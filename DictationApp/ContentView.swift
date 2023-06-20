//
//  ContentView.swift
//  DictationApp
//
//  Created by Dhakad on 18/05/23.
//

import SwiftUI
import AVFoundation
import WatchConnectivity
import UserNotifications
import MessageUI
import MobileCoreServices

struct ContentView: View {
    
    @State private var sendername: String = ""
    @State private var name: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var hostname: String = ""
    @State private var password: String = ""
    @State private var smtp: String = ""
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @State var getUserRecordingData: UserAudioData?
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TARGET")) {
                    
                    HStack {
                        Text("Email")
                            .font(.regularFont14)
                            .foregroundColor(.black)
                        Spacer()
                        TextField("email", text: $email)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("SMTP")) {
                    
                    HStack {
                        Text("Sendername")
                            .font(.regularFont14)
                        Spacer()
                        TextField("Name", text: $sendername)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Username")
                            .font(.regularFont14)
                            .foregroundColor(.black)
                        Spacer()
                        TextField("required", text: $username)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Password")
                            .font(.regularFont14)
                        Spacer()
                        SecureField("required", text: $password)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Hostname")
                            .font(.regularFont14)
                        Spacer()
                        TextField("smtp.example.com", text: $hostname)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("SMTP port")
                            .font(.regularFont14)
                        Spacer()
                        TextField("25", text: $smtp)
                            .font(.regularFont14)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                
                Button(action: {
                    saveInformation()
                    //sendMessageToWatch()
                }, label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                })
                
                HStack{
                    Text("Paired Watch Connectivity Status")
                    if connectivityManager.isWatchConnected {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .foregroundColor(.red)
                            .frame(width: 10, height: 10)
                    }
                }
            }

            .navigationTitle("Settings")
            .alert(isPresented: $isShowingAlert, content: {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            })
            .alert(item: $connectivityManager.notificationMessage) { message in
                DispatchQueue.main.async {
                    guard let userAudioData = message.userInfo["data"] as? Data else {
                        /// Handle the case where `userAudioData` is nil or not of type `Data`
                        return
                    }
                    self.getUserRecordingData = UserAudioData.decodeIt(userAudioData)
                    saveAudioFileInAppSpecificDirectory()
                }
#if DEBUG
                return Alert(title: Text("Succesfully Received Data from paired watch"),
                             dismissButton: .default(Text("Dismiss")))
#endif
            }
        }
    }
    
    /// This function required when iPhone get the succesfully recording data from the watch and send message to watch delete the audio  recoeding data from the apple watch document directory
    func sendMessageToWatch(){
        WatchConnectivityManager.shared.send("Delete Audio Files")
    }
    
    
    /// Function to save information into UserDefaults
    private func saveInformation() {
        guard !email.isEmpty && !name.isEmpty && !username.isEmpty && !hostname.isEmpty && !password.isEmpty && !smtp.isEmpty else {
            /// Show error dialog if any field is empty
            alertMessage = "Please fill in all fields."
            isShowingAlert = true
            return
        }
        
        // All fields have values, proceed with saving
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "Name")
        defaults.set(email, forKey: "Email")
        defaults.set(hostname, forKey: "HostName")
        defaults.set(password, forKey: "Password")
        defaults.set(smtp, forKey: "SMTP")
        
        /// Show success message or perform any additional logic
        alertMessage = "Information saved successfully."
        isShowingAlert = true
    }
    
    /// This Function required for saving the audio data which comes from apple watch
    func saveAudioFileInAppSpecificDirectory() {
        guard let userRecordingData = getUserRecordingData else {
#if DEBUG
            print("No user recording data available")
#endif
            return
        }
        
        guard !userRecordingData.audioData.isEmpty else {
#if DEBUG
            print("Audio data is empty")
#endif
            return
        }
        
        do {
            ///  Get the URL for the app's document directory
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            /// Check if the folder already exists
            if !FileManager.default.fileExists(atPath: documentDirectoryURL.path) {
                /// Create the document directory if it doesn't exist
                try FileManager.default.createDirectory(at: documentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            /// Generate a unique filename for the audio file
            let filename = userRecordingData.fileName
#if DEBUG
            print(filename)
#endif
            let fileURL = documentDirectoryURL.appendingPathComponent(filename)
            /// Save the audio data to the file URL
            try userRecordingData.audioData.write(to: fileURL)
            debugPrint("Audio file saved at: \(fileURL)")
            self.sendMessageToWatch()
        } catch {
            debugPrint("Failed to save audio file: \(error)")
        }
    }
    
    ///MARK: This function is required for fetch all the recording in the documnet directry
    func getAllSavedAudioFiles() {
        do {
            /// Get the URL for the app's document directory
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            /// Get the URLs of all files in the document directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: [])
            
            /// Filter the URLs to include only audio files (e.g., files with .m4a extension)
            let audioFileURLs = fileURLs.filter { $0.pathExtension == "m4a" }
            
            /// Print the list of audio file URLs
            for audioFileURL in audioFileURLs {
                print("Audio file: \(audioFileURL.lastPathComponent)")
            }
        } catch {
            print("Failed to get audio files: \(error)")
        }
    }
    
    /// This function required for deleteing the audio files once we can succesfully upload on server
    func deleteAllSavedAudioFiles() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs where fileURL.pathExtension == "m4a" {
                try FileManager.default.removeItem(at: fileURL)
                print("Succesfully Delted the file")
            }
        } catch  { print(error) }
    }
}

extension Font {
    static var regularFont14: Font {
        Font.system(size: 14, weight: .regular)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



extension ContentView{
    
    
    
}
