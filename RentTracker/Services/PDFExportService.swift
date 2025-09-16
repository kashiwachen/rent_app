import Foundation
import PDFKit
import SwiftUI

class PDFExportService {
    static let shared = PDFExportService()
    private init() {}

    func generateYearlyReport(year: Int) -> PDFDocument {
        let pdf = PDFDocument()
        let page = PDFPage(image: renderYearlyReportImage(year: year))
        if let page = page {
            pdf.insert(page, at: 0)
        }
        return pdf
    }

    func exportToTemporaryURL(_ document: PDFDocument, filename: String) -> URL? {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).pdf")
        guard let data = document.dataRepresentation() else { return nil }
        do {
            try data.write(to: tmp, options: .atomic)
            return tmp
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }

    private func renderYearlyReportImage(year: Int) -> UIImage {
        let size = CGSize(width: 612, height: 792) // US Letter
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let title = "Yearly Report - \(year)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            title.draw(at: CGPoint(x: 48, y: 48), withAttributes: attrs)

            let income = CoreDataService.shared.calculateYearlyIncome(year: year)
            let expenses = CoreDataService.shared.calculateYearlyExpenses(year: year)
            let net = income - expenses

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "¥"

            let lines = [
                "Total Income: \(formatter.string(from: income as NSDecimalNumber) ?? "-")",
                "Total Expenses: \(formatter.string(from: expenses as NSDecimalNumber) ?? "-")",
                "Net Income: \(formatter.string(from: net as NSDecimalNumber) ?? "-")"
            ]

            var y: CGFloat = 120
            for line in lines {
                (line as NSString).draw(at: CGPoint(x: 48, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 16)])
                y += 28
            }
        }
        return image
    }
}


