import AVFoundation
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecordingViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Button(
                    action: {
                        viewModel.toggleRecording()
                    },
                    label: {
                        Text(viewModel.isRecording ? "録音停止" : "録音開始")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                )
                .padding()
                List {
                    ForEach(viewModel.recordings, id: \.self) { recording in
                        HStack {
                            Text(recording.lastPathComponent)
                            Spacer()
                            Button(
                                action: {
                                    viewModel.togglePlayback(for: recording)
                                },
                                label: {
                                    Text(viewModel.isPlaying(recording) ? "停止" : "再生")
                                        .padding()
                                        .background(viewModel.isPlaying(recording) ? Color.red : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            )
                        }
                    }
                    .onDelete(perform: viewModel.deleteRecording)
                }
            }
            .navigationBarTitle("録音リスト")
            .onAppear {
                viewModel.requestMicrophonePermission()
                viewModel.loadRecordings()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
