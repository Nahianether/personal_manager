use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    headers::{Authorization, authorization::Bearer},
    TypedHeader,
};
use serde_json::{json, Value};
use bcrypt::{hash, verify, DEFAULT_COST};
use anyhow::Result;
use uuid::Uuid;
use chrono::Utc;
use validator::Validate;

use crate::models::{User, CreateUserRequest, LoginRequest, AuthResponse, UserResponse};
use crate::services::database::DbPool;
use crate::utils::jwt::{create_jwt, validate_jwt};

pub async fn signup(
    State(pool): State<DbPool>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Validate input
    if let Err(validation_errors) = payload.validate() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Validation failed",
                "details": validation_errors
            })),
        ));
    }

    // Check if user already exists
    let existing_user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1",
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await;

    match existing_user {
        Ok(Some(_)) => {
            return Err((
                StatusCode::CONFLICT,
                Json(json!({
                    "error": "User with this email already exists"
                })),
            ));
        }
        Ok(None) => {}
        Err(e) => {
            log::error!("Database error during user check: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Database error"
                })),
            ));
        }
    }

    // Hash password
    let password_hash = match hash(&payload.password, DEFAULT_COST) {
        Ok(hash) => hash,
        Err(e) => {
            log::error!("Failed to hash password: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Failed to hash password"
                })),
            ));
        }
    };

    // Generate UUID for user
    let user_id = Uuid::new_v4();
    let now = Utc::now();

    // Insert user into database
    let result = sqlx::query(
        "INSERT INTO users (id, name, email, password_hash, created_at, updated_at, is_active) VALUES ($1, $2, $3, $4, $5, $6, $7)",
    )
    .bind(&user_id)
    .bind(&payload.name)
    .bind(&payload.email)
    .bind(&password_hash)
    .bind(&now)
    .bind(&now)
    .bind(true)
    .execute(&pool)
    .await;

    match result {
        Ok(_) => {
            // Generate JWT token
            let token = match create_jwt(&user_id.to_string()) {
                Ok(token) => token,
                Err(e) => {
                    log::error!("Failed to create JWT token: {}", e);
                    return Err((
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(json!({
                            "error": "Failed to create token"
                        })),
                    ));
                }
            };

            // Create user response
            let user_response = UserResponse {
                id: user_id.to_string(),
                name: payload.name,
                email: payload.email,
                created_at: now,
                updated_at: now,
            };

            let response = AuthResponse {
                token,
                user: user_response,
            };

            log::info!("User registered successfully: {}", payload.email);
            Ok(Json(json!(response)))
        }
        Err(e) => {
            log::error!("Failed to create user: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Failed to create user"
                })),
            ))
        }
    }
}

pub async fn signin(
    State(pool): State<DbPool>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Validate input
    if let Err(validation_errors) = payload.validate() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Validation failed",
                "details": validation_errors
            })),
        ));
    }

    // Find user by email
    let user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1 AND is_active = true",
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await;

    let user = match user {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid email or password"
                })),
            ));
        }
        Err(e) => {
            log::error!("Database error during login: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Database error"
                })),
            ));
        }
    };

    // Verify password
    let is_valid = match verify(&payload.password, &user.password_hash) {
        Ok(valid) => valid,
        Err(e) => {
            log::error!("Failed to verify password: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Failed to verify password"
                })),
            ));
        }
    };

    if !is_valid {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "error": "Invalid email or password"
            })),
        ));
    }

    // Update last login timestamp
    let _ = sqlx::query(
        "UPDATE users SET last_login = $1 WHERE id = $2",
    )
    .bind(&Utc::now())
    .bind(&user.id)
    .execute(&pool)
    .await;

    // Generate JWT token
    let token = match create_jwt(&user.id.to_string()) {
        Ok(token) => token,
        Err(e) => {
            log::error!("Failed to create JWT token: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Failed to create token"
                })),
            ));
        }
    };

    let response = AuthResponse {
        token,
        user: UserResponse::from(user),
    };

    log::info!("User signed in successfully: {}", payload.email);
    Ok(Json(json!(response)))
}

pub async fn validate(
    State(pool): State<DbPool>,
    TypedHeader(authorization): TypedHeader<Authorization<Bearer>>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let token = authorization.token();
    
    // Validate JWT token
    let claims = match validate_jwt(token) {
        Ok(claims) => claims,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid or expired token"
                })),
            ));
        }
    };

    // Check if user exists and is active
    let user_id = match Uuid::parse_str(&claims.sub) {
        Ok(id) => id,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid token format"
                })),
            ));
        }
    };

    let user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1 AND is_active = true",
    )
    .bind(&user_id)
    .fetch_optional(&pool)
    .await;

    match user {
        Ok(Some(user)) => {
            Ok(Json(json!({
                "message": "Token is valid",
                "user": UserResponse::from(user)
            })))
        }
        Ok(None) => {
            Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "User not found or inactive"
                })),
            ))
        }
        Err(e) => {
            log::error!("Database error during token validation: {}", e);
            Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Database error"
                })),
            ))
        }
    }
}

pub async fn logout(
    TypedHeader(authorization): TypedHeader<Authorization<Bearer>>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let token = authorization.token();
    
    // Validate JWT token
    let claims = match validate_jwt(token) {
        Ok(claims) => claims,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid or expired token"
                })),
            ));
        }
    };

    // In a production system, you would typically:
    // 1. Add the token to a blacklist
    // 2. Or store active sessions in database and remove them
    // For now, we'll just return success since JWT is stateless
    
    log::info!("User logged out: {}", claims.sub);
    Ok(Json(json!({
        "message": "Logout successful"
    })))
}

pub async fn refresh_token(
    TypedHeader(authorization): TypedHeader<Authorization<Bearer>>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let token = authorization.token();
    
    // Validate current JWT token
    let claims = match validate_jwt(token) {
        Ok(claims) => claims,
        Err(_) => {
            return Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({
                    "error": "Invalid or expired token"
                })),
            ));
        }
    };

    // Generate new JWT token
    let new_token = match create_jwt(&claims.sub) {
        Ok(token) => token,
        Err(e) => {
            log::error!("Failed to create new JWT token: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": "Failed to create new token"
                })),
            ));
        }
    };

    Ok(Json(json!({
        "token": new_token
    })))
}