import AVFoundation
import Foundation

class RecordingViewModel: NSObject, ObservableObject {
    @Published var recordings: [URL] = []
    @Published var isRecording = false
    @Published var currentlyPlaying: URL?

    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var audioEngine: AVAudioEngine?
    var inputNode: AVAudioInputNode?
    var mixerNode: AVAudioMixerNode?

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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
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

            startMonitoring()

            isRecording = true
        } catch {
            print("録音開始に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        stopMonitoring()
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
            print("再生に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlaying = nil
    }

    func isPlaying(_ recording: URL) -> Bool {
        currentlyPlaying == recording
    }

    // 再生が終了したときに呼ばれるデリゲートメソッド
    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        currentlyPlaying = nil
        // 画面の更新をトリガーするためにリストを再読み込み
        objectWillChange.send()
    }

    func deleteRecording(at offsets: IndexSet) {
        let fileManager = FileManager.default
        for index in offsets {
            let recording = recordings[index]
            do {
                if isPlaying(recording) {
                    stopPlayback()
                }
                try fileManager.removeItem(at: recording)
            } catch {
                print("録音の削除に失敗しました: \(error.localizedDescription)")
            }
        }
        loadRecordings()
    }

    func startMonitoring() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        mixerNode = AVAudioMixerNode()

        guard let inputNode, let audioEngine, let mixerNode else { return }

        let format = inputNode.inputFormat(forBus: 0)
        audioEngine.attach(mixerNode)
        audioEngine.connect(inputNode, to: mixerNode, format: format)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: format)

        mixerNode.volume = 1.0

        do {
            try audioEngine.start()
        } catch {
            print("オーディオエンジンの開始に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopMonitoring() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        mixerNode = nil
    }
}

extension RecordingViewModel: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    // ここにデリゲートメソッドを追加
}
