
import Foundation

class Statistics {

    func save(game: Game) {
        guard let encodedData = try? JSONEncoder().encode(game) else {
            Log.error("failed to encode game \(game) for statistics")
            return
        }

        let fm = FileManager.default

        do {
            let gameDir = fm.currentDirectoryPath + "/games"
            if !fm.fileExists(atPath: gameDir) {
                try fm.createDirectory(atPath: gameDir, withIntermediateDirectories: true, attributes: nil)
            }

            let gameDataUrl = URL(fileURLWithPath: gameDir + "/\(game.id).json")
            try encodedData.write(to: gameDataUrl)

            Log.debug("saved game statistics to: \(gameDataUrl.absoluteString)")
        }
        catch {
            Log.error("failed to save statistics for game: \(game), error: \(error)")
        }
    }
}
