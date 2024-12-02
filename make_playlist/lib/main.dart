import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List selectedTracks = []; // 플레이리스트에 담긴 트랙 (track ID로 관리)
  final String apiUrl = 'http://192.168.0.4:3000/spotify'; // Node.js 서버 URL

  @override
  void initState() {
    super.initState();
    // InAppWebView 초기화
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlaylistSearchPage(
        selectedTracks: selectedTracks,
        onPlaylistUpdated: (newTracks) {
          setState(() {
            selectedTracks = newTracks; // 업데이트된 플레이리스트 상태 관리
          });
        },
      ),
    );
  }
}

class PlaylistSearchPage extends StatefulWidget {
  final List selectedTracks; // track ID로 관리된 리스트
  final Function(List) onPlaylistUpdated;

  const PlaylistSearchPage(
      {super.key,
      required this.selectedTracks,
      required this.onPlaylistUpdated});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List tracks = []; // 검색된 트랙 리스트
  bool isSidebarOpen = true; // 사이드바 상태 관리
  bool isLoading = false; // 로딩 상태
  int offset = 0; // Spotify API에서 10곡씩 가져오기 위한 오프셋

  final String apiUrl = 'http://192.168.0.4:3000/spotify'; // Node.js 서버 URL

  // Spotify 검색 API 호출
  Future<void> _searchSpotify() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || isLoading) return; // 로딩 중이거나 검색어가 비어 있으면 실행하지 않음

    setState(() {
      isLoading = true; // 로딩 상태로 설정
      tracks = []; // 새로운 검색을 시작할 때 기존 트랙 리스트 비우기
    });

    try {
      final response = await http.get(
        Uri.parse('$apiUrl?q=$query&limit=10&offset=$offset'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          tracks = data['tracks']['items']; // 검색된 트랙 리스트 업데이트
        });
      } else {
        throw Exception('Failed to load tracks');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false; // 로딩 상태 해제
      });
    }
  }

  // 플레이리스트에 노래 추가
  void _addToPlaylist(Map<String, dynamic> track) {
    // track['id']가 이미 selectedTracks에 없다면 추가
    if (!widget.selectedTracks
        .any((selectedTrack) => selectedTrack['id'] == track['id'])) {
      setState(() {
        widget.selectedTracks.add({
          'id': track['id'],
          'name': track['name'],
          'artists': track['artists'],
          'album': track['album'],
        }); // track의 모든 정보를 추가
      });
      widget.onPlaylistUpdated(widget.selectedTracks); // 상태 업데이트
    }
  }

  // 플레이리스트에서 노래 삭제
  void _removeFromPlaylist(Map<String, dynamic> track) {
    setState(() {
      widget.selectedTracks.removeWhere((selectedTrack) =>
          selectedTrack['id'] == track['id']); // track ID로 삭제
    });
    widget.onPlaylistUpdated(widget.selectedTracks); // 상태 업데이트
  }

  // 플레이리스트가 최소 10곡 이상일 때
  bool get isPlaylistComplete => widget.selectedTracks.length >= 10;

  // 플레이리스트 완성 여부 체크
  void _onComplete() {
    if (isPlaylistComplete) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyPlaylistPage(
            selectedTracks: widget.selectedTracks,
            onPlaylistUpdated: widget.onPlaylistUpdated, // 상태 전달
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("플레이리스트 미완성"),
          content: const Text("최소 10곡을 선택하세요."),
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

  // 사이드바 열고 닫기
  void _toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

  // 트랙을 클릭하여 WebView로 미리 듣기
  void _showTrackPreview(String trackId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 400,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                    'https://open.spotify.com/embed/track/$trackId'), // WebUri로 변환
              ),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true, // 자바스크립트 허용
                ),
              ),
              onWebViewCreated: (InAppWebViewController controller) {},
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 사이드바: 왼쪽에 플레이리스트 표시
          isSidebarOpen
              ? Container(
                  width: 250,
                  color: Colors.grey[200], // 사이드바 열릴 때 색깔 지정
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // "내 플레이리스트" 텍스트 가운데 정렬
                        const Center(
                          child: Text(
                            '내 플레이리스트',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
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
                                onTap: () =>
                                    _removeFromPlaylist(track), // 앨범 커버를 눌러서 삭제
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(), // 사이드바 닫을 경우 빈 컨테이너
          // 오른쪽: 검색 및 곡 정보 표시
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '나의 플레이리스트 만들기',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '최소 10곡을 골라 플레이리스트를 완성하세요. \n노래가 많을수록 분석 결과가 더욱 정확해집니다!',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search for songs or artists',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _searchSpotify(), // 엔터키로 검색
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searchSpotify, // 버튼 클릭으로 검색
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 검색 결과가 비어 있으면 로딩 중이나 결과 없음 표시
                  Expanded(
                    child: isLoading
                        ? const Center(child: Text('로딩 중...'))
                        : tracks.isEmpty
                            ? const Center(child: Text('No tracks found'))
                            : ListView.builder(
                                itemCount: tracks.length,
                                itemBuilder: (context, index) {
                                  final track = tracks[index];
                                  final isAlreadyAdded = widget.selectedTracks
                                      .any((selectedTrack) =>
                                          selectedTrack['id'] == track['id']);
                                  return ListTile(
                                    leading: track['album']['images'].isNotEmpty
                                        ? Image.network(
                                            track['album']['images'][0]['url'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.music_note),
                                    title: Text(track['name']),
                                    subtitle: Text(track['artists']
                                        .map((artist) => artist['name'])
                                        .join(', ')),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        if (isAlreadyAdded) {
                                          _removeFromPlaylist(
                                              track); // 이미 담긴 곡 삭제
                                        } else {
                                          _addToPlaylist(track); // 곡 담기
                                        }
                                      },
                                      child: Text(
                                          isAlreadyAdded ? '이미 담긴 곡' : '담기'),
                                    ),
                                    onTap: () {
                                      // 앨범 클릭 시 트랙 미리 듣기
                                      _showTrackPreview(track['id']);
                                    },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _onComplete,
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPlaylistComplete ? Colors.green : Colors.white),
                    child: const Text('완성'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 오른쪽 아래에 고정된 음악 아이콘 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSidebar,
        backgroundColor: Colors.blue, // 버튼 클릭 시 사이드바 열고 닫기
        child: Icon(Icons.audiotrack),
      ),
    );
  }
}
