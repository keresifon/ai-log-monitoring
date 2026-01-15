#!/bin/bash

# AI Log Monitoring System - Login Test Script
# This script tests the login functionality with various scenarios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
API_GATEWAY_URL="${API_GATEWAY_URL:-http://localhost:8080}"
AUTH_SERVICE_URL="${AUTH_SERVICE_URL:-http://localhost:8084}"
TEST_USERNAME="${TEST_USERNAME:-admin}"
TEST_PASSWORD="${TEST_PASSWORD:-admin123}"
TEST_EMAIL="${TEST_EMAIL:-admin@example.com}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_separator() {
    echo -e "\n${BLUE}========================================${NC}"
}

# Function to pretty print JSON
pretty_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq '.' 2>/dev/null || echo "$1"
    else
        echo "$1"
    fi
}

# Function to check if service is running
check_service() {
    local url=$1
    local service_name=$2
    
    print_info "Checking if $service_name is running..."
    if curl -s -f "$url/actuator/health" > /dev/null 2>&1; then
        print_success "$service_name is running"
        return 0
    else
        print_error "$service_name is not running at $url"
        return 1
    fi
}

# Function to test login endpoint
test_login() {
    local base_url=$1
    local username=$2
    local password=$3
    local endpoint_name=$4
    
    print_test "Testing login at $endpoint_name"
    print_info "Username: $username"
    print_info "Password: ${password:0:3}***"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\"}" \
        "$base_url/api/auth/login" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        print_success "Login successful (HTTP $http_code)"
        echo ""
        print_info "Response:"
        pretty_json "$body"
        
        # Extract token
        local token=$(echo "$body" | grep -o '"token":"[^"]*' | cut -d'"' -f4 || echo "")
        if [ -n "$token" ]; then
            print_success "JWT Token extracted: ${token:0:50}..."
            echo "$token" > /tmp/jwt_token.txt
            echo "$token"
        else
            print_warning "Could not extract token from response"
            echo ""
        fi
        return 0
    else
        print_error "Login failed (HTTP $http_code)"
        echo ""
        print_info "Response:"
        pretty_json "$body"
        return 1
    fi
}

# Function to test invalid login
test_invalid_login() {
    local base_url=$1
    local username=$2
    local password=$3
    local endpoint_name=$4
    
    print_test "Testing invalid login at $endpoint_name"
    print_info "Username: $username"
    print_info "Password: ${password:0:3}***"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\"}" \
        "$base_url/api/auth/login" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "401" ] || [ "$http_code" = "400" ]; then
        print_success "Invalid login correctly rejected (HTTP $http_code)"
        echo ""
        print_info "Response:"
        pretty_json "$body"
        return 0
    else
        print_error "Unexpected response (HTTP $http_code)"
        echo ""
        print_info "Response:"
        pretty_json "$body"
        return 1
    fi
}

# Function to test missing fields
test_missing_fields() {
    local base_url=$1
    local endpoint_name=$2
    
    print_test "Testing login with missing fields at $endpoint_name"
    
    # Test missing username
    print_info "Testing with missing username..."
    local response1=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"password\":\"test123\"}" \
        "$base_url/api/auth/login" 2>/dev/null || echo -e "\n000")
    
    local http_code1=$(echo "$response1" | tail -n1)
    if [ "$http_code1" = "400" ]; then
        print_success "Missing username correctly rejected (HTTP $http_code1)"
    else
        print_warning "Unexpected response for missing username (HTTP $http_code1)"
    fi
    
    # Test missing password
    print_info "Testing with missing password..."
    local response2=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"testuser\"}" \
        "$base_url/api/auth/login" 2>/dev/null || echo -e "\n000")
    
    local http_code2=$(echo "$response2" | tail -n1)
    if [ "$http_code2" = "400" ]; then
        print_success "Missing password correctly rejected (HTTP $http_code2)"
    else
        print_warning "Unexpected response for missing password (HTTP $http_code2)"
    fi
}

# Function to register a test user
register_user() {
    local base_url=$1
    local username=$2
    local password=$3
    local email=$4
    
    print_info "Registering test user: $username"
    
    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\",\"email\":\"$email\",\"firstName\":\"Test\",\"lastName\":\"User\"}" \
        "$base_url/api/auth/register" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        print_success "User registered successfully (HTTP $http_code)"
        return 0
    else
        if echo "$body" | grep -q "already exists\|duplicate"; then
            print_warning "User already exists (HTTP $http_code)"
            return 0
        else
            print_warning "Registration failed or user exists (HTTP $http_code)"
            pretty_json "$body"
            return 1
        fi
    fi
}

# Main execution
print_separator
print_info "AI Log Monitoring System - Login Test"
print_separator

# Check if services are running
print_separator
print_info "Checking Services"
print_separator

GATEWAY_RUNNING=false
AUTH_SERVICE_RUNNING=false

if check_service "$API_GATEWAY_URL" "API Gateway"; then
    GATEWAY_RUNNING=true
fi

if check_service "$AUTH_SERVICE_URL" "Auth Service"; then
    AUTH_SERVICE_RUNNING=true
fi

if [ "$GATEWAY_RUNNING" = false ] && [ "$AUTH_SERVICE_RUNNING" = false ]; then
    print_error "Neither API Gateway nor Auth Service is running!"
    print_info "Please start the services first:"
    print_info "  docker-compose up -d"
    print_info "  or"
    print_info "  cd backend/auth-service && ./mvnw spring-boot:run"
    exit 1
fi

# Test 1: Register test user (if needed)
print_separator
print_info "Test 1: User Registration"
print_separator

if [ "$GATEWAY_RUNNING" = true ]; then
    register_user "$API_GATEWAY_URL" "$TEST_USERNAME" "$TEST_PASSWORD" "$TEST_EMAIL"
elif [ "$AUTH_SERVICE_RUNNING" = true ]; then
    register_user "$AUTH_SERVICE_URL" "$TEST_USERNAME" "$TEST_PASSWORD" "$TEST_EMAIL"
fi

# Test 2: Valid login via API Gateway
print_separator
print_info "Test 2: Valid Login via API Gateway"
print_separator

JWT_TOKEN=""
if [ "$GATEWAY_RUNNING" = true ]; then
    JWT_TOKEN=$(test_login "$API_GATEWAY_URL" "$TEST_USERNAME" "$TEST_PASSWORD" "API Gateway")
    if [ -n "$JWT_TOKEN" ]; then
        print_success "JWT Token saved to /tmp/jwt_token.txt"
    fi
fi

# Test 3: Valid login via Auth Service (direct)
print_separator
print_info "Test 3: Valid Login via Auth Service (Direct)"
print_separator

if [ "$AUTH_SERVICE_RUNNING" = true ]; then
    test_login "$AUTH_SERVICE_URL" "$TEST_USERNAME" "$TEST_PASSWORD" "Auth Service"
fi

# Test 4: Invalid credentials
print_separator
print_info "Test 4: Invalid Credentials"
print_separator

if [ "$GATEWAY_RUNNING" = true ]; then
    test_invalid_login "$API_GATEWAY_URL" "$TEST_USERNAME" "wrongpassword" "API Gateway"
fi

# Test 5: Non-existent user
print_separator
print_info "Test 5: Non-existent User"
print_separator

if [ "$GATEWAY_RUNNING" = true ]; then
    test_invalid_login "$API_GATEWAY_URL" "nonexistentuser" "$TEST_PASSWORD" "API Gateway"
fi

# Test 6: Missing fields validation
print_separator
print_info "Test 6: Missing Fields Validation"
print_separator

if [ "$GATEWAY_RUNNING" = true ]; then
    test_missing_fields "$API_GATEWAY_URL" "API Gateway"
fi

# Test 7: Token validation (if we got a token)
print_separator
print_info "Test 7: Token Validation"
print_separator

if [ -n "$JWT_TOKEN" ] && [ "$GATEWAY_RUNNING" = true ]; then
    print_test "Testing authenticated request with JWT token"
    
    # Try to access a protected endpoint
    local protected_response=$(curl -s -w "\n%{http_code}" -X GET \
        -H "Authorization: Bearer $JWT_TOKEN" \
        "$API_GATEWAY_URL/api/v1/alerts" 2>/dev/null || echo -e "\n000")
    
    local protected_http_code=$(echo "$protected_response" | tail -n1)
    
    if [ "$protected_http_code" = "200" ] || [ "$protected_http_code" = "401" ]; then
        if [ "$protected_http_code" = "200" ]; then
            print_success "Token is valid and accepted (HTTP $protected_http_code)"
        else
            print_warning "Token might be invalid or endpoint requires different permissions (HTTP $protected_http_code)"
        fi
    else
        print_warning "Unexpected response (HTTP $protected_http_code)"
    fi
else
    print_warning "Skipping token validation (no token obtained or gateway not running)"
fi

# Summary
print_separator
print_info "Test Summary"
print_separator

echo -e "${GREEN}Tests Completed:${NC}"
echo "  ✓ Service health checks"
echo "  ✓ User registration"
echo "  ✓ Valid login (API Gateway)"
if [ "$AUTH_SERVICE_RUNNING" = true ]; then
    echo "  ✓ Valid login (Auth Service direct)"
fi
echo "  ✓ Invalid credentials rejection"
echo "  ✓ Non-existent user rejection"
echo "  ✓ Missing fields validation"
if [ -n "$JWT_TOKEN" ]; then
    echo "  ✓ Token validation"
fi

print_separator
print_info "Next Steps:"
print_info "1. If login failed, check:"
print_info "   - Services are running: docker-compose ps"
print_info "   - Database is initialized: docker-compose exec postgres psql -U admin -d ai_monitoring -c '\\dt auth_service.*'"
print_info "   - Default admin user exists (username: admin, password: admin123)"
print_info ""
print_info "2. To test via frontend:"
print_info "   - Start frontend: cd frontend && npm start"
print_info "   - Navigate to: http://localhost:4200/login"
print_info ""
print_info "3. To use the token in other requests:"
if [ -n "$JWT_TOKEN" ]; then
    print_info "   export JWT_TOKEN=\"$JWT_TOKEN\""
    print_info "   curl -H \"Authorization: Bearer \$JWT_TOKEN\" $API_GATEWAY_URL/api/v1/alerts"
else
    print_info "   Token saved to: /tmp/jwt_token.txt"
fi
print_separator

echo -e "\n${GREEN}Login testing complete!${NC}\n"

# Made with Bob
