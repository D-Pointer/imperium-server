
#import "ScenarioReader.h"
#import "MapLayer.h"
#import "PolygonNode.h"
#import "TBXML.h"
#import "Definitions.h"
#import "Unit.h"
#import "Globals.h"
#import "MissionVisualizer.h"
#import "Scenario.h"

@interface ScenarioReader () {
    int mapHeight;
    int mapWidth;
    
    CCArray * polygons;
    CCArray * textures;
    
    MapLayer * mapLayer;
}                             

- (TerrainType) getTerrainTypeForId:(NSString *)polygon_id;
- (void) createDefaultTerrain;

@end


@implementation ScenarioReader

- (id) init {
    
	if ((self = [super init])) {        
        // polygon storage
        polygons = [CCArray array];

        // load all textures
        textures = [CCArray array];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"woods.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"field.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"grass.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"sand.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"water.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"roof.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"swamp.jpg"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"rocky2.png"] ];
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"beach.jpg"] ];        
        [textures addObject:[[CCTextureCache sharedTextureCache] addImage:@"ford.jpg"] ];        
	}
    
	return self;
}


- (TerrainType) getTerrainTypeForId:(NSString *)polygon_id {
    if ( [polygon_id isEqualToString:@"woods"] ) {
        return kWoods;
    }
    
    else if ( [polygon_id isEqualToString:@"field"] ) {
        return kField;
    }
    
    else if ( [polygon_id isEqualToString:@"road"] ) {
        return kRoad;
    }
        
    else if ( [polygon_id isEqualToString:@"grass"] ) {
        return kGrass;
    }

    else if ( [polygon_id isEqualToString:@"river"] ) {
        return kRiver;
    }
    
    else if ( [polygon_id isEqualToString:@"swamp"] ) {
        return kSwamp;
    }
    
    else if ( [polygon_id isEqualToString:@"rocky"] ) {
        return kRocky;
    }
    
    else if ( [polygon_id isEqualToString:@"beach"] ) {
        return kBeach;
    }
    
    else if ( [polygon_id isEqualToString:@"house"] ) {
        return kRoof;
    }
    
    else if ( [polygon_id isEqualToString:@"ford"] ) {
        return kFord;
    }

    // invalid...
    NSAssert1( NO, @"Invalid polygon id: %@", polygon_id );        
    return kGrass;
}


- (void) setOutlineColorForPolygon:(PolygonNode *)polygon {
    switch ( polygon.terrainType ) {
        case kWoods:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 0, 80, 0 );
            break;

        case kField:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 110, 60, 0 );
            break;

        case kRiver:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 0, 0, 200 );
            break;

        case kRoof:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 40, 40, 40 );
            break;

        case kSwamp:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 30, 55, 65 );
            break;
            
        case kBeach:
            polygon.renderOutline = YES;
            polygon.outlineColor  = ccc3( 165, 100, 0 );
            break;
            
        case kFord:
        default:
            polygon.renderOutline = NO;
            break;
    }
}


- (void) parsePath:(TBXMLElement *)element {
    // get the type and id
    NSString * polygon_type = [TBXML valueOfAttributeNamed:@"inkscape:label" forElement:element];
    NSString * polygon_id   = [TBXML valueOfAttributeNamed:@"id" forElement:element];
    
    CCLOG( @"parsing: %@", polygon_id );
    
    // extract the real data, the "d"
    NSString * data = [TBXML valueOfAttributeNamed:@"d" forElement:element];    
    NSAssert( data != nil, @"Invalid <path> element" );
    
    // get rid of the last "z" if present
    data = [data stringByReplacingOccurrencesOfString:@"z" withString:@""];
    
    // precautions
    NSAssert( [data length] > 0, @"Invalid d in path" );
    
    unichar type, tmp;
    
    NSString * accum = @"";
    
    // current position
    CGPoint pos = ccp( 0, 0 );
    
    // result vertices
    CCArray * vertices = [CCArray array];
    
    // loop all characters in the "d" string
    for ( unsigned int index = 0; index < [data length]; ++index ) {
        tmp = [data characterAtIndex:index];

        // new parsed type?
        if ( tmp == 'M' || tmp == 'm' || tmp == 'L' || tmp == 'l' || index == [data length] - 1 ) {
            // first type?
            if ( accum.length == 0 ) {
                // precautions
                if ( tmp == 'm' ) {
                    type = 'M';
                }
                else {
                    type = tmp;
                }
                
                continue;
            }

            //CCLOG( @"ScenarioParser.parsePath: completed '%c' = '%@'", type, accum );                

            // trim the number a bit
            accum = [accum stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            accum = [accum stringByReplacingOccurrencesOfString:@" " withString:@","];
            
            // split based on "," to two separate strings that can be parsed to numbers
            NSArray * numbers = [accum componentsSeparatedByString:@","];            
            NSAssert( numbers.count == 2, @"Invalid accum" );
            
            // parse to numbers
            float x = [[numbers objectAtIndex:0] floatValue];
            float y = [[numbers objectAtIndex:1] floatValue];

            // so, what did we actually get?
            switch ( type ) {
                case 'M':
                    y = mapHeight - y;
                    pos = CGPointMake( x, y );
                    break;
                    
                case 'm':
                    y = -y;
                    pos = CGPointMake( pos.x + x, pos.y + y );   
                    break;

                case 'L':
                    y = mapHeight - y;
                    pos = CGPointMake( x, y );
                    break;

                case 'l':
                    y = -y;
                    pos = CGPointMake( pos.x + x, pos.y + y );   
                    break;
            }

            //CCLOG( @"ScenarioParser.parsePath: '%c' - new vertex: %.f %.f", type, pos.x, pos.y );                                    

            // save for later
            [vertices addObject:[NSValue valueWithCGPoint:pos]];
            
            // not yet last?
            if ( index < [data length] - 1 ) {
                type = tmp;
                
                // start a new number
                accum = @"";
            }
        }

        // number?
        else if ( isnumber( tmp ) || tmp == '-' || tmp == '.' || tmp == ',' || tmp == ' ') {
            // part of a number
            accum = [accum stringByAppendingFormat:@"%c", tmp];
        }
    }
    
    //CCLOG( @"ScenarioParser.parsePath: creating polygon for %@", polygon_type );
    
    // create a polygon node and position it properly
    PolygonNode * polygon_node = [[PolygonNode alloc] initWithPolygon:vertices 
                                                                color:ccc4( 255, 255, 255, 255 ) 
                                                            smoothing:YES];

    // find a texture for the polygon
    polygon_node.terrainType = [self getTerrainTypeForId:polygon_type];
    polygon_node.texture     = [textures objectAtIndex:polygon_node.terrainType];
    polygon_node.position    = ccp( 0, 0 );
    [mapLayer addChild:polygon_node z:kTerrainZ];   
    
    // set up the outline if any
    [self setOutlineColorForPolygon:polygon_node];
    
    // save for later too
    [polygons addObject:polygon_node];
    
//    for ( unsigned int index = 0; index < vertices.count; ++index ) {
//        CGPoint pos = [[vertices objectAtIndex:index] CGPointValue];
//        CCSprite * sprite = [CCSprite spriteWithSpriteFrameName:@"dot.png"];
//        sprite.position = pos;
//        [self addChild:sprite];
//    }
}


- (void) parseUnit:(TBXMLElement *)element forOwner:(PlayerId)player {
    // position
    float x      = [[TBXML valueOfAttributeNamed:@"x" forElement:element] floatValue];
    float y      = [[TBXML valueOfAttributeNamed:@"y" forElement:element] floatValue];

    // dimensions not really used
    float width  = [[TBXML valueOfAttributeNamed:@"width" forElement:element] floatValue];
    float height = [[TBXML valueOfAttributeNamed:@"height" forElement:element] floatValue];

    // various id data
    NSString * unit_info = [TBXML valueOfAttributeNamed:@"id" forElement:element];

    // possible name
    TBXMLElement * title_element = [TBXML childElementNamed:@"title" parentElement:element];
    NSString * title = title_element == nil ? @"No name!" : [TBXML textForElement:title_element];
    
    // does it have a transform?
    NSString * transform = [TBXML valueOfAttributeNamed:@"transform" forElement:element];
    NSAssert( transform, @"No transform for unit" );
    NSAssert( [transform hasPrefix:@"matrix("], @"No matrix transform for unit" );

    transform = [transform stringByReplacingOccurrencesOfString:@"matrix(" withString:@""];
    transform = [transform stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@")"]];
    
    NSArray * values = [transform componentsSeparatedByString:@","];
    float a = [[values objectAtIndex:0] floatValue];
    float b = [[values objectAtIndex:1] floatValue];
    float c = [[values objectAtIndex:2] floatValue];
    float d = [[values objectAtIndex:3] floatValue];
    float e = [[values objectAtIndex:4] floatValue];
    float f = [[values objectAtIndex:5] floatValue];
    
    // see http://en.wikipedia.org/wiki/User_talk:Tooto#Co-ordinate_system_transformation
    
    // old center
    x += width / 2.0f;
    y += height / 2.0f;
    
    // new modified center
    CGPoint pos = ccp( a * x + c * y + e, b * x + d * y + f );
    
    CCLOG( @"%d %f", mapHeight, pos.y );
    
    // flip y
    pos.y = mapHeight - pos.y;   
    
    // the angle the unit has been rotated
    float angle = atan2f( c, a );

    // split the "type_abc_def_" data
    NSArray * data = [unit_info componentsSeparatedByString:@"_"];            

    // parse out the type string. the type is 'inf', 'cav' or 'art'
    NSString * type_string = [data objectAtIndex:0];
    UnitType type;
    
    if ( [type_string isEqualToString:@"inf"] ) {
        type = kInfantry;
    }
    else if ( [type_string isEqualToString:@"cav"] ) {
        type = kCavalry;
    }
    else if ( [type_string isEqualToString:@"art"] ) {
        type = kArtillery;
    }
    else if ( [type_string isEqualToString:@"hq"] ) {
        type = kHeadquarter;
    }
    else {
        NSAssert1( NO, @"Invalid unit type: %@", type_string );
    }
    
    //CCLOG( @"ScenarioParser.parseUnit: '%@', type: %d pos: %f,%f, angle: %f", title, type, pos.x, pos.y, angle );
    
    // the unit's initial mode
    UnitMode mode = [[data objectAtIndex:4] intValue];
    
    // create the real unit
    Unit * unit = [Unit createUnitType:type forOwner:player withMode:mode];
    unit.position = pos;
    
    // misc data
    unit.unitId = [[data objectAtIndex:3] intValue];
    unit.name   = title;

    // simulated data
    short men  = [[data objectAtIndex:1] intValue] & 0xffff;
    short guns = [[data objectAtIndex:2] intValue] & 0xffff;
    
    // the rotation goes the other way, thus the -
    float facing = -CC_RADIANS_TO_DEGREES( angle );
    unit.rotation = facing;
    
    // setup the initial simulation data
    [unit.data setInitialMen:men guns:guns facing:facing position:pos mode:mode];
    
    // and set up the scale for the unit to match the men it has
    [unit setupScaleForMen:men];

    // any headquarter?
    NSString * hq_string = [data objectAtIndex:5];
    if ( ! [hq_string isEqualToString:@"x"] ) {
        unit.headquarterId = [hq_string intValue];
    }
    
    // save for later
    [mapLayer addChild:unit z:kUnitZ];    
    [[Globals sharedInstance].units addObject:unit];
    
    // add a mission visualizer for the local human player's units
    if ( ( player == kPlayer1 && [Globals sharedInstance].player1.type == kLocalPlayer ) ||  ( player == kPlayer2 && [Globals sharedInstance].player2.type == kLocalPlayer ) ) {
        unit.missionVisualizer = [[MissionVisualizer alloc] initWithUnit:unit];
        [mapLayer addChild:unit.missionVisualizer z:kMissionVisualizerZ];                
    }

    // add to the right container too
    if ( player == kPlayer1 ) {
        [[Globals sharedInstance].unitsPlayer1 addObject:unit];
    }
    else {
        [[Globals sharedInstance].unitsPlayer2 addObject:unit];        
    }
}


- (void) parseObjective:(TBXMLElement *)element {
    // position
    float x      = [[TBXML valueOfAttributeNamed:@"x" forElement:element] floatValue];
    float y      = [[TBXML valueOfAttributeNamed:@"y" forElement:element] floatValue];
    float width  = [[TBXML valueOfAttributeNamed:@"width" forElement:element] floatValue];
    float height = [[TBXML valueOfAttributeNamed:@"height" forElement:element] floatValue];

    // title
    TBXMLElement * title_element = [TBXML childElementNamed:@"title" parentElement:element];
    NSString * title = title_element == nil ? @"Unnamed objective!" : [TBXML textForElement:title_element];
    
    // flip y
    y = mapHeight - y;
    
    Objective * objective = [Objective spriteWithSpriteFrameName:@"ObjectiveNeutral.png"];
    objective.position = ccp( x + width * 0.5, y - height * 0.5 );
    objective.title = title;
    
    // save for later
    [mapLayer addChild:objective z:kObjectiveZ];    
    [[Globals sharedInstance].objectives addObject:objective];    
}


- (void) parseRect:(TBXMLElement *)element {
    // get the id
    NSString * rect_id = [TBXML valueOfAttributeNamed:@"inkscape:label" forElement:element];
    
    // a unit?
    if ( [rect_id isEqualToString:@"unit1"] ) {
        [self parseUnit:element forOwner:kPlayer1];
        return;        
    }    
    else if ( [rect_id isEqualToString:@"unit2"] ) {
        [self parseUnit:element forOwner:kPlayer2];
        return;        
    }
    else if ( [rect_id isEqualToString:@"objective"] ) {
        [self parseObjective:element];
        return;        
    }
    
    // dimensions
    float x      = [[TBXML valueOfAttributeNamed:@"x" forElement:element] floatValue];
    float y      = [[TBXML valueOfAttributeNamed:@"y" forElement:element] floatValue];
    float width  = [[TBXML valueOfAttributeNamed:@"width" forElement:element] floatValue];
    float height = [[TBXML valueOfAttributeNamed:@"height" forElement:element] floatValue];

    // result vertices
    CCArray * vertices = [CCArray arrayWithCapacity:4];
    CGPoint corner1, corner2, corner3, corner4;
    
    // does it have a transform?
    NSString * transform = [TBXML valueOfAttributeNamed:@"transform" forElement:element];
    if ( transform && [transform hasPrefix:@"matrix("] ) {
        transform = [transform stringByReplacingOccurrencesOfString:@"matrix(" withString:@""];
        transform = [transform stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@")"]];
        
        NSArray * values = [transform componentsSeparatedByString:@","];
        float a = [[values objectAtIndex:0] floatValue];
        float b = [[values objectAtIndex:1] floatValue];
        float c = [[values objectAtIndex:2] floatValue];
        float d = [[values objectAtIndex:3] floatValue];
        float e = [[values objectAtIndex:4] floatValue];
        float f = [[values objectAtIndex:5] floatValue];
        
        // see http://en.wikipedia.org/wiki/User_talk:Tooto#Co-ordinate_system_transformation
        
        // old center
        //float cx = x + width / 2.0f;
        //float cy = y + height / 2.0f;
        
        // new modified center
        float cx = a * x + c * y + e;
        float cy = b * x + d * y + f;
        
        // flip cy
        cy = mapHeight - cy - height / 2.0f;                

        // corners of the house
        corner1 = ccp( cx,         cy - height / 2.0f );
        corner2 = ccp( cx,         cy + height / 2.0f );
        corner3 = ccp( cx + width, cy + height / 2.0f );
        corner4 = ccp( cx + width, cy - height / 2.0f );

        CGPoint center = ccp( cx, cy ); 

        // the angle the house has been rotated
        float angle = atan2f( c, a );

        [vertices addObject:[NSValue valueWithCGPoint:ccpRotateByAngle( corner1, center, angle )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccpRotateByAngle( corner2, center, angle )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccpRotateByAngle( corner3, center, angle )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccpRotateByAngle( corner4, center, angle )]];
    }
    
    else {        
        // flip y as the y is wrong way in the file!
        y = mapHeight - y - height / 2.0f;                

        // corners of the house
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x,         y - height / 2.0f )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x,         y + height / 2.0f )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x + width, y + height / 2.0f )]];
        [vertices addObject:[NSValue valueWithCGPoint:ccp( x + width, y - height / 2.0f )]];
    }    

    // create a polygon node and position it properly. no smoothing!
    PolygonNode * polygon_node = [[PolygonNode alloc] initWithPolygon:vertices 
                                                                color:ccc4( 255, 255, 255, 255 ) 
                                                            smoothing:NO];
    
    // find a texture for the polygon
    polygon_node.terrainType = [self getTerrainTypeForId:rect_id];
    polygon_node.texture     = [textures objectAtIndex:polygon_node.terrainType];
    polygon_node.position    = ccp( 0, 0 );
    [mapLayer addChild:polygon_node z:kHouseZ];   

    // set up the outline if any
    [self setOutlineColorForPolygon:polygon_node];

    // save for later too
    [polygons addObject:polygon_node];
}

/*
- (void) parseMetadata:(TBXMLElement *)element {
    TBXMLElement * child;
    
    // two levels of extra cruft first
    child = [TBXML childElementNamed:@"rdf:RDF" parentElement:element];
    if ( child == nil ) {
        CCLOG( @"ScenarioParser.parseMetadata: no <rdf::RDF> tag, skipping description");
        return;
    }

    child = [TBXML childElementNamed:@"cc:Work" parentElement:child];
    if ( child == nil ) {
        CCLOG( @"ScenarioParser.parseMetadata: no <cc:Work> tag, skipping description");
        return;
    }

    // title
    TBXMLElement * title = [TBXML childElementNamed:@"dc:title" parentElement:child];    
    if ( title != nil ) {
        [Globals sharedInstance].scenario.title = [TBXML textForElement:title];
        CCLOG( @"ScenarioParser.parseMetadata: scenario title: %@", [Globals sharedInstance].scenario.title );
    }
    
    // description
    TBXMLElement * description = [TBXML childElementNamed:@"dc:description" parentElement:child];
    if ( description != nil ) {
        [Globals sharedInstance].scenario.description = [TBXML textForElement:description];
        CCLOG( @"ScenarioParser.parseMetadata: scenario description: %@", [Globals sharedInstance].scenario.description );
    }
    
    // start time and turns
    TBXMLElement * date = [TBXML childElementNamed:@"dc:date" parentElement:child];    
    if ( date != nil ) {
        NSArray * parts = [[TBXML textForElement:date] componentsSeparatedByString:@" "];
        [Globals sharedInstance].scenario.startTime = [[parts objectAtIndex:0] intValue];
        [Globals sharedInstance].scenario.turns     = [[parts objectAtIndex:1] intValue];
        CCLOG( @"ScenarioParser.parseMetadata: scenario start time: %lu", [Globals sharedInstance].scenario.startTime );
        CCLOG( @"ScenarioParser.parseMetadata: scenario turns: %d", [Globals sharedInstance].scenario.turns );
    }
}
*/

- (void) createDefaultTerrain {
    CCSprite * grass;
    
    for ( int y = 0; y < mapHeight; ) {
        for ( int x = 0; x < mapWidth; ) {
            grass = [CCSprite spriteWithFile:@"grass.jpg"];
            grass.anchorPoint = ccp( 0, 0 );
            grass.position = ccp( x, y );
            [mapLayer addChild:grass z:kBackgroundZ];
            
            x += grass.boundingBox.size.width;
        }

        // next row
        y += grass.boundingBox.size.height;
    }
}


- (void) parseScenario:(NSString *)name forMap:(MapLayer *)mapLayer_ {
    mapLayer = mapLayer_;
    
    NSError *error;

    // try to parse the file
    TBXML * xml = [TBXML tbxmlWithXMLFile:name error:&error];
    
    if (error) {
        CCLOG( @"%@ %@", [error localizedDescription], [error userInfo]);
        return;
    } 

    // start from the root
    TBXMLElement * root = xml.rootXMLElement;

    // read the map dimensions
    mapWidth  = [[TBXML valueOfAttributeNamed:@"width" forElement:root] intValue];    
    mapHeight = [[TBXML valueOfAttributeNamed:@"height" forElement:root] intValue];    

    CCLOG( @"map size: %d %d", mapWidth, mapHeight );
    
    // setup the default background
    [self createDefaultTerrain];
    
    // first child
    TBXMLElement * child = root->firstChild;

    // loop all children of the root
    while ( child ) {
        // did we find the "g"?
        if ( [[TBXML elementName:child] isEqualToString:@"g"] ) {
            // now loop all children of that "g" node, there should be stuff we want
            TBXMLElement * element = child->firstChild;
            while ( element ) {
                // found a "path" element?
                if ( [[TBXML elementName:element] isEqualToString:@"path"] ) {
                    [self parsePath:element];
                }
                
                // did we find a rect?
                else if ( [[TBXML elementName:element] isEqualToString:@"rect"] ) {
                    [self parseRect:element];
                }
                
                // next sibling element
                element = element->nextSibling;
            }
        }

//        else if ( [[TBXML elementName:child] isEqualToString:@"metadata"] ) {
//            [self parseMetadata:child];
//        }
        
        // next sibling
        child = child->nextSibling;
    }

    // and we're done
    mapLayer.polygons  = polygons;
    mapLayer.mapWidth  = mapWidth;
    mapLayer.mapHeight = mapHeight;
    
    CCLOG( @"scenario parsed ok" );
}

@end
