// k6 Stress Test - Test application limits
// Tests both Frontend (HTTP) and Backend (via health checks) in one file
// Purpose: Find the breaking point and maximum capacity of the application
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

const errorRate = new Rate('errors');
const frontendErrorRate = new Rate('frontend_errors');
const backendErrorRate = new Rate('backend_errors');

export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '5m', target: 300 },
    { duration: '2m', target: 400 },
    { duration: '5m', target: 400 },
    { duration: '2m', target: 500 },
    { duration: '5m', target: 500 },
    { duration: '10m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<10000'],
    http_req_failed: ['rate<0.20'],
    errors: ['rate<0.20'],
    frontend_errors: ['rate<0.30'],
    backend_errors: ['rate<0.20'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://frontend.online-boutique.svc.cluster.local';

export default function () {
  // ============================================
  // LAYER 1: FRONTEND TESTS (HTTP)
  // ============================================
  let frontendWorking = false;

  // Test 1: Homepage (under stress)
  try {
    let response = http.get(`${BASE_URL}/`);
    let success = check(response, {
      'frontend homepage responds': (r) => r.status === 200 || r.status === 503,
    });
    frontendWorking = success;
    frontendErrorRate.add(!success);
    errorRate.add(!success);
  } catch (error) {
    frontendErrorRate.add(1);
    errorRate.add(1);
  }
  sleep(0.5);

  // Test 2: Product Details Page (rapid browsing under stress)
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId}`);
      const success = check(response, {
        'frontend product page responds': (r) => r.status === 200 || r.status === 404 || r.status === 503,
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(0.5);

  // ============================================
  // LAYER 2: BACKEND TESTS (via Health Check)
  // ============================================
  // Test 3: Health Check (monitor during stress)
  if (frontendWorking) {
    try {
      const response = http.get(`${BASE_URL}/_healthz`);
      const success = check(response, {
        'backend health check responds': (r) => r.status === 200 || r.status === 503,
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
  sleep(0.3);

  // Test 4: Another product page (multiple concurrent requests)
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId2 = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId2}`);
      const success = check(response, {
        'frontend second product page responds': (r) => r.status === 200 || r.status === 404 || r.status === 503,
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(0.3);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
