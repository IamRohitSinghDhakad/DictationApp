//
//  MailView.swift
//  DictationApp
//
//  Created by Dhakad on 16/06/23.
//

import Foundation
import SwiftUI
import MessageUI
import MobileCoreServices

struct MailView: UIViewControllerRepresentable {
    @Binding var showMailView: Bool
    let recipientEmail: String
    let subject: String
    let messageBody: String
    let attachmentData: Data?
    let attachmentMimeType: String
    let attachmentFileName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = context.coordinator
        mailComposeVC.setToRecipients([recipientEmail])
        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(messageBody, isHTML: false)

        if let data = attachmentData {
            mailComposeVC.addAttachmentData(data, mimeType: attachmentMimeType, fileName: attachmentFileName)
        }

        return mailComposeVC
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Empty implementation
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.showMailView = false
        }
    }
}
