import Foundation
import AVFoundation

class RecordingViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published var recordings: [URL] = []
    @Published var isRecording = false
    @Published var currentlyPlaying: URL? = nil

    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?

    func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            if !granted {
                // マイク使用許可が得られなかった場合の処理
                print("マイク使用許可が得られませんでした。")
            }
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let url = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
        } catch {
            // 録音開始に失敗した場合のエラーハンドリング
            print("録音開始に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        loadRecordings()
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func loadRecordings() {
        recordings.removeAll()
        let fileManager = FileManager.default
        let documentsDirectory = getDocumentsDirectory()

        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            recordings = files.filter { $0.pathExtension == "m4a" }
        } catch {
            // ファイルの読み込みに失敗した場合のエラーハンドリング
            print("ファイルの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    func togglePlayback(for recording: URL) {
        if currentlyPlaying == recording {
            stopPlayback()
        } else {
            startPlayback(for: recording)
        }
    }

    func startPlayback(for recording: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            currentlyPlaying = recording
        } catch {
            // 再生に失敗した場合のエラーハンドリング
            print("再生に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlaying = nil
    }

    func isPlaying(_ recording: URL) -> Bool {
        return currentlyPlaying == recording
    }

    // 再生が終了したときに呼ばれるデリゲートメソッド
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentlyPlaying = nil
        // 画面の更新をトリガーするためにリストを再読み込み
        objectWillChange.send()
    }

    func deleteRecording(_ recording: URL) {
        let fileManager = FileManager.default
        do {
            if isPlaying(recording) {
                stopPlayback()
            }
            try fileManager.removeItem(at: recording)
            loadRecordings()
        } catch {
            // 録音の削除に失敗した場合のエラーハンドリング
            print("録音の削除に失敗しました: \(error.localizedDescription)")
        }
    }
}