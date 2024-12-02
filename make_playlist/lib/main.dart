import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PlaylistSearchPage(),
    );
  }
}

class PlaylistSearchPage extends StatefulWidget {
  @override
  _PlaylistSearchPageState createState() => _PlaylistSearchPageState();
}

class _PlaylistSearchPageState extends State<PlaylistSearchPage> {
  TextEditingController _searchController = TextEditingController();
  List tracks = []; // 검색된 트랙 리스트
  List selectedTracks = []; // 플레이리스트에 담긴 트랙 (track ID로 관리)
  bool isSidebarOpen = false; // 사이드바 상태 관리
  bool isLoading = false; // 로딩 상태
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
        Uri.parse('$apiUrl?q=$query'),
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
    if (!selectedTracks
        .any((selectedTrack) => selectedTrack['id'] == track['id'])) {
      setState(() {
        selectedTracks.add({
          'id': track['id'],
          'name': track['name'],
          'artists': track['artists'],
          'album': track['album'],
        });
        isSidebarOpen = true; // 트랙이 추가되면 사이드바 열기
      });
    }
  }

  // 플레이리스트에서 노래 삭제
  void _removeFromPlaylist(Map<String, dynamic> track) {
    setState(() {
      selectedTracks
          .removeWhere((selectedTrack) => selectedTrack['id'] == track['id']);
    });
  }

  // 사이드바 열고 닫기
  void _toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Playlist Search'),
        actions: [
          // 사이드바 토글 버튼 (AppBar 우측에 배치)
          IconButton(
            icon: Icon(isSidebarOpen ? Icons.close : Icons.menu),
            onPressed: _toggleSidebar,
          ),
        ],
      ),
      body: Row(
        children: [
          // 사이드바: 왼쪽에 플레이리스트 표시
          isSidebarOpen
              ? Container(
                  width: 250,
                  color: Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
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
                            itemCount: selectedTracks.length,
                            itemBuilder: (context, index) {
                              final track = selectedTracks[index];
                              return ListTile(
                                leading: track['album']['images'].isNotEmpty
                                    ? Image.network(
                                        track['album']['images'][0]['url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(Icons.music_note),
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
                    '최소 10곡을 골라 플레이리스트를 완성하세요!',
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
                                  final isAlreadyAdded = selectedTracks.any(
                                      (selectedTrack) =>
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
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
