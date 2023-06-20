//
//  ContentView.swift
//  DictationApp Watch App
//
//  Created by Dhakad on 18/05/23.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    
    //MARK: Local Variables
    @State private var isRecordingLabelVisible = false
    @State private var isRecordingStopped = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordingSession: AVAudioSession?
    @State var recordingURL: URL?
    @State var recordingData: Data?
    @State var recordingFileExtension = ".m4a"
    @State var recordingAudioFileName : String?
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack {
            if isRecordingLabelVisible {
                Text("Recording...")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .padding()
            }
            
            if !isRecordingStopped {
                Button("Stop Recording") {
                    stopRecording()
                    isRecordingLabelVisible = false
                    isRecordingStopped = true
                }
            }
            if isRecordingStopped {
                Button(action: {
                    playRecording()
                    isRecordingLabelVisible = false
                }) {
                    Text("Play Recording")
                }
            }
            
            Button(action: {
                DispatchQueue.main.async {
                    if self.recordingData != nil{
                        WatchConnectivityManager.shared.sendDataToPhone(UserAudioData(fileName: recordingAudioFileName!, fileExtension: recordingFileExtension, audioData: recordingData!))
                    }else{
                        debugPrint("recording data is null \(String(describing: recordingData))")
                    }
                }
            }) {
                Text("Send Data To Iphone")
            }
        }
        
        .onAppear(perform: {
            setupAudioRecorder()
        })
        
        ///This function invokes when watch detect any notification comes from iphone side using WCSession
        .onReceive(connectivityManager.$notificationMessage) { message in
            if let unwrappedMessage = message {
                handleNotificationMessage(unwrappedMessage)
            }
        }
    }
    
    ///This function handle the notification response and perform the operation which required to be done
    func handleNotificationMessage(_ message: NotificationMessage) {
        if message.message == "Delete Audio Files"{
            self.deleteAllSavedAudioFiles()
        }else{
            ///Do Nothing
        }
    }
    
    /// This function required for setup the audio recorder and player to initialize the recording
    private func setupAudioRecorder() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("Can not setup the Recording")
        }
        
        /// Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        /// Generate a unique audio file name based on the current Date time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let currentDateTime = dateFormatter.string(from: Date())
        let audioFileName = "\(currentDateTime)" + recordingFileExtension
        recordingAudioFileName = audioFileName
        /// Create the URL for the audio file
        let audioFileURL = documentsDirectory.appendingPathComponent(audioFileName)
        
        let recordingSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                               AVSampleRateKey:12000,
                         AVNumberOfChannelsKey:1,
                      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            /// Create an AVAudioRecorder instance with the audio file URL and settings
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recordingSettings)
            /// Prepare the audio recorder for recording
            audioRecorder?.prepareToRecord()
        } catch {
            /// Handle any errors that occur during setup
            print("Error setting up audio recorder: \(error.localizedDescription)")
        }
        
        /// Show the "Recording..." label
        isRecordingLabelVisible = true
        
        /// Start recording
        startRecording()
    }
    
    private func startRecording() {
        /// Start recording audio
        audioRecorder?.record()
    }
    
    private func stopRecording() {
        /// Stop recording audio
        audioRecorder?.stop()
        recordingURL = audioRecorder?.url
        saveRecordingURL()
    }
    
    private func playRecording() {
        /// Get the URL of the recorded audio file
        guard let audioFileURL = audioRecorder?.url else {
            return
        }
        
        do {
            /// Create an AVAudioPlayer instance with the audio file URL
#if DEBUG
            print(audioFileURL)
#endif
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            /// Play the recorded audio
            audioPlayer?.play()
        } catch {
            /// Handle any errors that occur during playback
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    /// Save the recording URL and data  in local variables for sending the iPhone
    func saveRecordingURL() {
        guard let recordingURL = recordingURL else {
            return
        }
        do {
            let audioData = try Data(contentsOf: recordingURL)
            self.recordingData = audioData
        } catch {
#if DEBUG
            debugPrint("error ---\(error)")
#endif
        }
    }
    
    ///MARK: This function is required for fetch all the recording in the documnet directry
    func getAllSavedAudioFiles() {
        do {
            // Get the URL for the app's document directory
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            // Get the URLs of all files in the document directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil, options: [])
            // Filter the URLs to include only audio files (e.g., files with .m4a extension)
            let audioFileURLs = fileURLs.filter { $0.pathExtension == "m4a" }
            // Print the list of audio file URLs
            for audioFileURL in audioFileURLs {
#if DEBUG
                debugPrint("Audio file: \(audioFileURL.lastPathComponent)")
#endif
            }
            deleteAllSavedAudioFiles()
        } catch {
#if DEBUG
            debugPrint("Failed to get audio files: \(error)")
#endif
            
        }
    }
    
    ///MARK: This function is required for delete the audio files that saved in apple watch directory after conferming iphone receivved the recording data we are performing this
    func deleteAllSavedAudioFiles() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs where fileURL.pathExtension == "m4a" {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
