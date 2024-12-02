import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'main.dart';

void main() {
  runApp(MyApp());
}

class MyPlaylistPage extends StatefulWidget {
  final List selectedTracks;
  final Function(List) onPlaylistUpdated;

  const MyPlaylistPage(
      {super.key,
      required this.selectedTracks,
      required this.onPlaylistUpdated});

  @override
  _MyPlaylistPageState createState() => _MyPlaylistPageState();
}

class _MyPlaylistPageState extends State<MyPlaylistPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // ConfettiController를 하나로 통합하여 위쪽으로 떨어지게 설정
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // 플레이리스트에서 노래 삭제
  void _removeTrack(BuildContext context, Map<String, dynamic> track) {
    setState(() {
      // 새로운 리스트 생성 (삭제할 트랙을 제외한 리스트)
      widget.selectedTracks
          .removeWhere((selectedTrack) => selectedTrack['id'] == track['id']);
    });

    // 삭제 후 상태 업데이트
    widget.onPlaylistUpdated(widget.selectedTracks); // 상태 업데이트
  }

  // '완성' 버튼 눌렀을 때 처리
  void _onComplete(BuildContext context) {
    if (widget.selectedTracks.length >= 10) {
      // Confetti 애니메이션 시작
      _confettiController.play();

      // 완료 팝업 표시
      showDialog(
        context: context,
        barrierDismissible: false, // 바깥쪽을 눌러서 닫을 수 없도록 설정
        builder: (_) => AlertDialog(
          title: const Text(
            "축하합니다!",
            textAlign: TextAlign.center, // 제목 가운데 정렬
          ),
          content: const Text(
            '플레이리스트가 완성되었습니다!',
            textAlign: TextAlign.center, // 본문 텍스트 가운데 정렬
            style: TextStyle(fontSize: 14), // 텍스트 크기 조정
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                // '확인' 버튼 클릭 후 더 담기 화면으로 이동
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistSearchPage(
                      selectedTracks: widget.selectedTracks,
                      onPlaylistUpdated: widget.onPlaylistUpdated,
                    ),
                  ),
                );
              },
              child: const Text("확인"),
            ),
          ],
        ),
      );
    } else {
      // 10곡 미만이면 경고 메시지 띄움
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("플레이리스트 미완성"),
          content: const Text("최소 10곡을 담아야 합니다. 더 담아주세요."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 플레이리스트'),
        backgroundColor: Colors.blue,
        leading: Container(), // 왼쪽 화살표 버튼 제거
      ),
      body: Stack(
        children: [
          // 위쪽에서 Confetti 애니메이션
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -3.14 / 2, // 위쪽으로 퍼지도록 설정
            gravity: 0.1, // 중력 설정 (입자가 천천히 떨어지도록 조절)
            numberOfParticles: 100,
            emissionFrequency: 0.05,
            colors: const [
              Colors.red,
              Colors.green,
              Colors.blue,
              Colors.yellow
            ], // 여러 색상 설정
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: widget.selectedTracks.isEmpty
                      ? const Center(child: Text('플레이리스트에 곡이 없습니다.'))
                      : ListView.builder(
                          itemCount: widget.selectedTracks.length,
                          itemBuilder: (context, index) {
                            final track = widget.selectedTracks[index];
                            return ListTile(
                              leading: track['album']['images'].isNotEmpty
                                  ? Image.network(
                                      track['album']['images'][0]['url'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.music_note),
                              title: Text('${index + 1}. ${track['name']}'),
                              subtitle: Text(track['artists']
                                  .map((artist) => artist['name'])
                                  .join(', ')),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeTrack(context, track),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                // '더 담기' 버튼과 '완성' 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // 더 담기 버튼을 누르면 main.dart로 이동
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistSearchPage(
                              selectedTracks: widget.selectedTracks,
                              onPlaylistUpdated: widget.onPlaylistUpdated,
                            ),
                          ),
                        );
                      },
                      child: const Text('더 담기'),
                    ),
                    ElevatedButton(
                      onPressed: () => _onComplete(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.selectedTracks.length >= 10
                            ? Colors.green
                            : Colors.white,
                      ),
                      child: const Text('완성'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
