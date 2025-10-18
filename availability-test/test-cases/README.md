# Test Cases Structure

This directory contains all test cases for the availability testing application.

## Structure

```
test-cases/
├── __init__.py              # Test case registry and management
├── README.md               # This file
└── cart-services/          # Cart services test case
    └── cart_test.py        # Cart functionality tests
```

## Adding New Test Cases

To add a new test case:

1. **Create a new directory** for your test case:
   ```bash
   mkdir test-cases/your-service-name
   ```

2. **Create the test file**:
   ```python
   # test-cases/your-service-name/your_test.py
   class YourServiceTest:
       def test_your_functionality(self):
           # Your test logic here
           pass
   ```

3. **Register the test case** in `__init__.py`:
   ```python
   TEST_CASES = {
       'cart_services': {
           'name': 'Cart Services Test',
           'description': 'Tests cart add/remove functionality',
           'class': CartServicesTest,
           'enabled': True
       },
       'your_service': {  # Add your new test case
           'name': 'Your Service Test',
           'description': 'Tests your service functionality',
           'class': YourServiceTest,
           'enabled': True
       }
   }
   ```

## Test Case Guidelines

- Each test case should be self-contained
- Test cases should return standardized results
- Include proper error handling
- Add detailed logging for debugging
- Follow the existing naming conventions

## Current Test Cases

### Cart Services Test
- **Location**: `cart-services/cart_test.py`
- **Purpose**: Tests cart add/remove functionality
- **Status**: ✅ Enabled
