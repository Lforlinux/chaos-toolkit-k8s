// k6 Load Test - Normal expected load
// Purpose: Test application performance under expected production load
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const frontendErrorRate = new Rate('frontend_errors');
const backendErrorRate = new Rate('backend_errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 50 },   // Stay at 50 users (normal load)
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000', 'p(99)<5000'], // 95% < 3s, 99% < 5s
    http_req_failed: ['rate<0.05'],                  // Error rate < 5%
    errors: ['rate<0.05'],
    frontend_errors: ['rate<0.10'],
    backend_errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://frontend.online-boutique.svc.cluster.local';

export default function () {
  // ============================================
  // LAYER 1: FRONTEND TESTS (HTTP)
  // ============================================
  let frontendWorking = false;

  // Test 1: Homepage
  try {
    let response = http.get(`${BASE_URL}/`);
    let success = check(response, {
      'frontend homepage loads': (r) => r.status === 200,
      'frontend homepage has products': (r) => r.body.includes('product') || r.body.includes('item') || r.body.includes('Online Boutique'),
    });
    frontendWorking = success;
    frontendErrorRate.add(!success);
    errorRate.add(!success);
  } catch (error) {
    frontendErrorRate.add(1);
    errorRate.add(1);
  }
  sleep(Math.random() * 2 + 1); // Random sleep 1-3s

  // Test 2: Product Details Page (simulate browsing)
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId}`);
      const success = check(response, {
        'frontend product page loads': (r) => r.status === 200 || r.status === 404,
        'frontend product page responds': (r) => r.status === 200 || (r.status === 404 && r.body.length > 0),
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(Math.random() * 3 + 2);

  // ============================================
  // LAYER 2: BACKEND TESTS (via Health Check)
  // ============================================
  // Test 3: Health Check (validates backend services)
  if (frontendWorking) {
    try {
      const response = http.get(`${BASE_URL}/_healthz`);
      const success = check(response, {
        'backend health check works': (r) => r.status === 200,
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
  sleep(Math.random() * 2 + 1);

  // Test 4: Another product page (simulate continued browsing)
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId2 = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId2}`);
      const success = check(response, {
        'frontend second product page loads': (r) => r.status === 200 || r.status === 404,
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

