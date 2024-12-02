const express = require('express');
const axios = require('axios');
const cors = require('cors'); // CORS 패키지 임포트
const app = express();
const port = 3000;

app.use(cors()); // CORS 미들웨어 사용

// Spotify API 액세스 토큰
const token = '<TOKEN>'; // 실제 토큰으로 교체

// Spotify API 요청을 프록시하는 엔드포인트
app.get('/spotify', async (req, res) => {
  const query = req.query.q;  // 쿼리 파라미터로 전달된 검색어
  const limit = parseInt(req.query.limit) || 10; // 기본값은 10
  const offset = parseInt(req.query.offset) || 0; // 기본값은 0

  if (!query) {
    return res.status(400).send('Query parameter "q" is required');
  }

  try {
    // Spotify API에 요청 보내기
    const response = await axios.get('https://api.spotify.com/v1/search', {
      params: {
        q: query,  // 검색어
        type: 'track',  // 검색할 타입 (track은 노래)
        limit: limit,  // 최대 limit 개의 결과
        offset: offset, // offset으로 페이지네이션 구현
      },
      headers: {
        Authorization: `Bearer ${token}`,  // Spotify Access Token
      },
    });

    // 받은 데이터를 클라이언트에 반환
    console.log('Spotify API Response:', response.status, response.data);  // 응답 상태와 데이터 로그
    res.json(response.data); // 클라이언트에 데이터를 반환
  } catch (error) {
    // Spotify API 호출 실패 시 에러 로그 및 응답
    console.error('Error during Spotify API request:', error.response ? error.response.data : error.message);
    res.status(500).send('Failed to fetch data from Spotify API');
  }
});

// 서버 시작
app.listen(port, () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
});
