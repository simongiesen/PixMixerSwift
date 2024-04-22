import Foundation

func main() {
    let arguments = CommandLine.arguments
    guard arguments.count == 2 else {
        print("Bitte geben Sie den Dateipfad des JPEG-Bildes als Argument an.")
        return
    }

    let inputImagePath = arguments[1]
    guard FileManager.default.fileExists(atPath: inputImagePath) else {
        print("Die angegebene Datei existiert nicht.")
        return
    }

    do {
        guard let originalImage = NSImage(contentsOfFile: inputImagePath) else {
            print("Das Bild konnte nicht geladen werden.")
            return
        }

        let width = Int(originalImage.size.width) / 2
        let height = Int(originalImage.size.height) / 2

        var quadrants: [NSImage] = []

        let quadrantRects: [NSRect] = [
            NSRect(x: 0, y: 0, width: width, height: height),
            NSRect(x: width, y: 0, width: width, height: height),
            NSRect(x: 0, y: height, width: width, height: height),
            NSRect(x: width, y: height, width: width, height: height)
        ]

        for rect in quadrantRects {
            if let quadrant = originalImage.subimage(with: rect) {
                quadrants.append(quadrant)
            }
        }

        let resultWidth = Int(originalImage.size.width) + width
        let resultHeight = Int(originalImage.size.height) + height * 2

        let resultImage = NSImage(size: NSSize(width: resultWidth, height: resultHeight))
        resultImage.lockFocus()

        NSColor.white.set()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: resultWidth, height: resultHeight)).fill()

        originalImage.draw(at: .zero)
        quadrants[0].draw(at: NSPoint(x: Int(originalImage.size.width), y: Int(originalImage.size.height)))
        quadrants[2].draw(at: NSPoint(x: Int(originalImage.size.width), y: Int(originalImage.size.height) - height))
        quadrants[1].draw(at: NSPoint(x: Int(originalImage.size.width) - width, y: Int(originalImage.size.height)))

        resultImage.unlockFocus()

        guard let data = resultImage.tiffRepresentation else {
            print("Fehler beim Konvertieren des Bildes.")
            return
        }

        let outputImagePath = (inputImagePath as NSString).deletingPathExtension + "_result.jpg"

        guard let imageRep = NSBitmapImageRep(data: data) else {
            print("Fehler beim Erstellen des Bilds.")
            return
        }

        let jpegData = imageRep.representation(using: .jpeg, properties: [:])
        try jpegData?.write(to: URL(fileURLWithPath: outputImagePath))

        print("Das Ergebnisbild wurde unter \(outputImagePath) gespeichert.")
    } catch {
        print("Ein Fehler ist aufgetreten: \(error.localizedDescription)")
    }
}

main()
