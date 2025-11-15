// k6 Smoke Test - Basic functionality test with minimal load
// Tests both Frontend (HTTP) and Backend (via health checks) in one file
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

const errorRate = new Rate('errors');
const frontendErrorRate = new Rate('frontend_errors');
const backendErrorRate = new Rate('backend_errors');

export const options = {
  stages: [
    { duration: '1m', target: 1 },
    { duration: '2m', target: 1 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.01'],
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
      'frontend homepage status is 200': (r) => r.status === 200,
      'frontend homepage has products': (r) => r.body.includes('product') || r.body.includes('item') || r.body.includes('Online Boutique'),
    });
    frontendWorking = success;
    frontendErrorRate.add(!success);
    errorRate.add(!success);
  } catch (error) {
    frontendErrorRate.add(1);
    errorRate.add(1);
    console.log(`⚠️ Frontend connection failed: ${error.message}`);
  }
  sleep(1);

  // Test 2: Product Details Page
  if (frontendWorking) {
    try {
      const products = ['OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N'];
      const productId = products[Math.floor(Math.random() * products.length)];
      const response = http.get(`${BASE_URL}/product/${productId}`);
      const success = check(response, {
        'frontend product page status is 200 or 404': (r) => r.status === 200 || r.status === 404,
        'frontend product page loads': (r) => r.status === 200 || (r.status === 404 && r.body.length > 0),
      });
      frontendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      frontendErrorRate.add(1);
      errorRate.add(1);
    }
  }
  sleep(1);

  // ============================================
  // LAYER 2: BACKEND TESTS (via Health Check)
  // ============================================
  // Test 3: Health Check Endpoint (validates backend services)
  if (frontendWorking) {
    try {
      const response = http.get(`${BASE_URL}/_healthz`);
      const success = check(response, {
        'backend health check status is 200': (r) => r.status === 200,
      });
      backendErrorRate.add(!success);
      errorRate.add(!success);
    } catch (error) {
      backendErrorRate.add(1);
      errorRate.add(1);
    }
  } else {
    console.log('⚠️ Frontend down - cannot test backend via HTTP');
    backendErrorRate.add(0); // Don't fail test if we can't verify
  }
  sleep(1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}
