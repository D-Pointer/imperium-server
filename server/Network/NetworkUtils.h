#ifndef NETWORK_UTILS_H
#define NETWORK_UTILS_H

static unsigned short saveInt8ToBuffer (unsigned char value, unsigned char * buffer, unsigned short offset) {
    buffer[ offset ] = value;
    return offset + sizeof( unsigned char );
}


static unsigned short saveInt16ToBuffer (unsigned short value, unsigned char * buffer, unsigned short offset) {
    value = htons( value );
    memcpy( buffer + offset, &value, sizeof( unsigned short ) );
    return offset + sizeof( unsigned short );
}


static unsigned short saveInt32ToBuffer (unsigned int value, unsigned char * buffer, unsigned short offset) {
    value = htonl( value );
    memcpy( buffer + offset, &value, sizeof( unsigned int ) );
    return offset + sizeof( unsigned int );
}


static unsigned short readInt16FromBuffer (const unsigned char * buffer, unsigned short * offset) {
    unsigned short value;
    memcpy( &value, buffer + *offset, sizeof( unsigned short ) );
    value = ntohs( value );
    *offset += sizeof( unsigned short );
    return value;
}


static unsigned int readInt32FromBuffer (const unsigned char * buffer, unsigned short * offset) {
    unsigned int value;
    memcpy( &value, buffer + *offset, sizeof( unsigned int ) );
    value = ntohl( value );
    *offset += sizeof( unsigned int );
    return value;
}

#endif
