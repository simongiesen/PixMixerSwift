import Foundation
import AppKit

// Funktion zum Zuschneiden des Bildes
func cropImage(_ image: NSImage, to rect: NSRect) -> NSImage? {
    let croppedImage = NSImage(size: rect.size)
    croppedImage.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: rect.size), from: rect, operation: .copy, fraction: 1.0)
    croppedImage.unlockFocus()
    return croppedImage
}

func processImage(atPath path: String) {
    guard FileManager.default.fileExists(atPath: path) else {
        print("Die angegebene Datei existiert nicht.")
        return
    }

    guard let image = NSImage(contentsOfFile: path) else {
        print("Konnte das Bild nicht laden.")
        return
    }

    let originalSize = image.size

    guard let tiffData = image.tiffRepresentation,
          let imageRep = NSBitmapImageRep(data: tiffData),
          let dpi = imageRep.resolution else {
        print("Konnte die DPI-Auflösung des Bildes nicht abrufen.")
        return
    }

    let width = Int(originalSize.width / 2)
    let height = Int(originalSize.height / 2)

    // Überlappung zwischen den Quadranten
    let overlap = 1

    // Quadranten bestimmen
    let rects = [
        NSRect(x: 0, y: 0, width: CGFloat(width - overlap), height: CGFloat(height - overlap)), // oben links
        NSRect(x: CGFloat(width - overlap), y: 0, width: CGFloat(width - overlap), height: CGFloat(height - overlap)), // oben rechts
        NSRect(x: 0, y: CGFloat(height - overlap), width: CGFloat(width - overlap), height: CGFloat(height - overlap)), // unten links
        NSRect(x: CGFloat(width - overlap), y: CGFloat(height - overlap), width: CGFloat(width - overlap), height: CGFloat(height - overlap)) // unten rechts
    ]

    var quadrants: [NSImage] = []

    for rect in rects {
        if let quadrant = cropImage(image, to: rect) {
            quadrants.append(quadrant)
        } else {
            print("Konnte Quadranten nicht erstellen.")
            return
        }
    }

    // Erstellung des Ergebnisbildes
    let resultWidth = originalSize.width + CGFloat(width - overlap)
    let resultHeight = originalSize.height + CGFloat(2 * height - overlap)
    let resultSize = NSSize(width: resultWidth, height: resultHeight)

    let resultImage = NSImage(size: resultSize)
    resultImage.lockFocus()
    NSColor.white.set()
    NSBezierPath.fill(NSRect(origin: .zero, size: resultSize))

    // Originalbild oben links
    image.draw(at: NSPoint(x: 0, y: originalSize.height), from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0)

    // Platzierung der Quadranten
    quadrants[0].draw(at: NSPoint(x: originalSize.width - CGFloat(overlap), y: originalSize.height - CGFloat(overlap)), from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0) // oben links im unteren rechten Eck
    quadrants[2].draw(at: NSPoint(x: originalSize.width - CGFloat(overlap), y: originalSize.height - CGFloat(height - overlap)), from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0) // unten links im unteren rechten Eck
    quadrants[1].draw(at: NSPoint(x: originalSize.width - CGFloat(width - overlap), y: originalSize.height - CGFloat(overlap)), from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0) // oben rechts im unteren rechten Eck
    quadrants[3].draw(at: NSPoint(x: originalSize.width - CGFloat(width - overlap), y: originalSize.height - CGFloat(height - overlap)), from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0) // unten rechts links neben Quadrant 2

    resultImage.unlockFocus()

    // Setzen der DPI-Auflösung für das Ergebnisbild
    resultImage.representations.forEach {
        if let rep = $0 as? NSBitmapImageRep {
            rep.size = resultSize
            rep.resolution = dpi
        }
    }

    // Ergebnisbild speichern
    let outputPath = (path as NSString).deletingLastPathComponent + "/" + (path as NSString).lastPathComponent + "_result.jpg"

    guard let imageData = resultImage.tiffRepresentation(using: .jpeg, factor: 1.0),
          let bitmapImageRep = NSBitmapImageRep(data: imageData),
          let jpegData = bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0]) else {
        print("Konnte das Ergebnisbild nicht speichern.")
        return
    }

    do {
        try jpegData.write(to: URL(fileURLWithPath: outputPath))
        print("Das Ergebnisbild wurde unter \(outputPath) gespeichert.")
    } catch {
        print("Ein Fehler ist aufgetreten: \(error.localizedDescription)")
    }
}

let arguments = CommandLine.arguments

if arguments.count != 2 {
    print("Bitte geben Sie den Dateipfad des JPEG-Bildes als Argument an.")
} else {
    processImage(atPath: arguments[1])
}
