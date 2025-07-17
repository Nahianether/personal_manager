use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use validator::Validate;

// User model for database
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub password_hash: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub last_login: Option<DateTime<Utc>>,
    pub is_active: bool,
}

// User response (without password hash)
#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: String,
    pub name: String,
    pub email: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        UserResponse {
            id: user.id.to_string(),
            name: user.name,
            email: user.email,
            created_at: user.created_at,
            updated_at: user.updated_at,
        }
    }
}

// Request models
#[derive(Debug, Deserialize, Validate)]
pub struct CreateUserRequest {
    #[validate(length(min = 2, max = 255, message = "Name must be between 2 and 255 characters"))]
    pub name: String,
    
    #[validate(email(message = "Please provide a valid email address"))]
    pub email: String,
    
    #[validate(length(min = 6, message = "Password must be at least 6 characters long"))]
    pub password: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email(message = "Please provide a valid email address"))]
    pub email: String,
    
    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

// Response models
#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserResponse,
}

// JWT Claims
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,  // Subject (user ID)
    pub exp: usize,   // Expiration time
    pub iat: usize,   // Issued at
}

// Account models (for the financial data)
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Account {
    pub id: Uuid,
    pub user_id: Uuid,
    pub name: String,
    pub account_type: String,
    pub balance: f64,
    pub currency: String,
    pub credit_limit: Option<f64>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateAccountRequest {
    #[validate(length(min = 1, max = 255, message = "Name is required"))]
    pub name: String,
    
    #[validate(length(min = 1, message = "Account type is required"))]
    pub account_type: String,
    
    pub balance: f64,
    
    #[validate(length(min = 1, max = 10, message = "Currency is required"))]
    pub currency: String,
    
    pub credit_limit: Option<f64>,
}

// Transaction models
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Transaction {
    pub id: Uuid,
    pub user_id: Uuid,
    pub account_id: Uuid,
    pub transaction_type: String,
    pub amount: f64,
    pub currency: String,
    pub category: Option<String>,
    pub description: Option<String>,
    pub date: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateTransactionRequest {
    pub account_id: String,
    
    #[validate(length(min = 1, message = "Transaction type is required"))]
    pub transaction_type: String,
    
    pub amount: f64,
    
    #[validate(length(min = 1, max = 10, message = "Currency is required"))]
    pub currency: String,
    
    pub category: Option<String>,
    pub description: Option<String>,
    pub date: DateTime<Utc>,
}

// Loan models
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Loan {
    pub id: Uuid,
    pub user_id: Uuid,
    pub person_name: String,
    pub amount: f64,
    pub currency: String,
    pub loan_date: DateTime<Utc>,
    pub return_date: Option<DateTime<Utc>>,
    pub is_returned: bool,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub is_historical_entry: bool,
    pub account_id: Option<Uuid>,
    pub transaction_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateLoanRequest {
    #[validate(length(min = 1, max = 255, message = "Person name is required"))]
    pub person_name: String,
    
    pub amount: f64,
    
    #[validate(length(min = 1, max = 10, message = "Currency is required"))]
    pub currency: String,
    
    pub loan_date: DateTime<Utc>,
    pub return_date: Option<DateTime<Utc>>,
    pub description: Option<String>,
    pub is_historical_entry: Option<bool>,
    pub account_id: Option<String>,
    pub transaction_id: Option<String>,
}

// Liability models
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Liability {
    pub id: Uuid,
    pub user_id: Uuid,
    pub person_name: String,
    pub amount: f64,
    pub currency: String,
    pub due_date: DateTime<Utc>,
    pub is_paid: bool,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub is_historical_entry: bool,
    pub account_id: Option<Uuid>,
    pub transaction_id: Option<Uuid>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateLiabilityRequest {
    #[validate(length(min = 1, max = 255, message = "Person name is required"))]
    pub person_name: String,
    
    pub amount: f64,
    
    #[validate(length(min = 1, max = 10, message = "Currency is required"))]
    pub currency: String,
    
    pub due_date: DateTime<Utc>,
    pub description: Option<String>,
    pub is_historical_entry: Option<bool>,
    pub account_id: Option<String>,
    pub transaction_id: Option<String>,
}