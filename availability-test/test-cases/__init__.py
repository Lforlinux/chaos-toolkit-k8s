"""
Test Cases Registry
Manages all available test cases for the availability testing application
"""

from .cart_services.cart_test import CartServicesTest

# Registry of all available test cases
TEST_CASES = {
    'cart_services': {
        'name': 'Cart Services Test',
        'description': 'Tests cart add/remove functionality',
        'class': CartServicesTest,
        'enabled': True
    }
}

def get_test_case(test_name):
    """Get a test case by name"""
    return TEST_CASES.get(test_name)

def get_all_test_cases():
    """Get all available test cases"""
    return TEST_CASES

def get_enabled_test_cases():
    """Get only enabled test cases"""
    return {name: config for name, config in TEST_CASES.items() if config.get('enabled', True)}
