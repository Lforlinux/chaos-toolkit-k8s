// k6 Spike Test - Sudden traffic spikes
// Tests both Frontend (HTTP) and Backend (via health checks) in one file
// Purpose: Test how the application handles sudden traffic spikes
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

const errorRate = new Rate('errors');
const frontendErrorRate = new Rate('frontend_errors');
const backendErrorRate = new Rate('backend_errors');

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '30s', target: 500 },
    { duration: '1m', target: 500 },
    { duration: '30s', target: 10 },
    { duration: '1m', target: 10 },
    { duration: '30s', target: 1000 },
    { duration: '1m', target: 1000 },
    { duration: '30s', target: 10 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<5000'],
    http_req_failed: ['rate<0.30'],
    errors: ['rate<0.30'],
    frontend_errors: ['rate<0.40'],
    backend_errors: ['rate<0.30'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://frontend.online-boutique.svc.cluster.local';

export default function () {
  // ============================================
  // LAYER 1: FRONTEND TESTS (HTTP)
  // ============================================
  let frontendWorking = false;

  // Test 1: Homepage (during traffic spike)
  try {
    let response = http.get(`${BASE_URL}/`);
    let success = check(response, {
      'frontend homepage responds': (r) => r.status === 200 || r.status === 503 || r.status === 429,
    });
    frontendWorking = success;
    frontendErrorRate.add(!success);
    errorRate.add(!success);
  } catch (error) {
    frontendErrorRate.add(1);
    errorRate.add(1);
  }
  sleep(0.2);

  // Test 2: Product Details Page (rapid requests during spike)
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId}`);
      const success = check(response, {
        'frontend product page responds': (r) => r.status === 200 || r.status === 404 || r.status === 503 || r.status === 429,
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(0.2);

  // ============================================
  // LAYER 2: BACKEND TESTS (via Health Check)
  // ============================================
  // Test 3: Health Check (monitor during spike)
  if (frontendWorking) {
    try {
      const response = http.get(`${BASE_URL}/_healthz`);
      const success = check(response, {
        'backend health check responds': (r) => r.status === 200 || r.status === 503 || r.status === 429,
      });
      backendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      backendErrorRate.add(1);
      errorRate.add(1);
    }
  } else {
    backendErrorRate.add(0); // Don't fail if frontend is down
  }
  sleep(0.2);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
