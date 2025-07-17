use jsonwebtoken::{encode, decode, Header, Algorithm, Validation, EncodingKey, DecodingKey};
use anyhow::{Result, anyhow};
use chrono::{Utc, Duration};
use std::env;

use crate::models::Claims;

// Get JWT secret from environment variable
fn get_jwt_secret() -> String {
    env::var("JWT_SECRET").unwrap_or_else(|_| "your-default-secret-key-change-in-production".to_string())
}

// Create JWT token
pub fn create_jwt(user_id: &str) -> Result<String> {
    let secret = get_jwt_secret();
    let now = Utc::now();
    let expiration = now + Duration::days(7); // Token expires in 7 days

    let claims = Claims {
        sub: user_id.to_string(),
        exp: expiration.timestamp() as usize,
        iat: now.timestamp() as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )?;

    Ok(token)
}

// Validate JWT token
pub fn validate_jwt(token: &str) -> Result<Claims> {
    let secret = get_jwt_secret();
    
    let validation = Validation::new(Algorithm::HS256);
    
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &validation,
    )?;

    // Check if token is expired
    let now = Utc::now().timestamp() as usize;
    if token_data.claims.exp < now {
        return Err(anyhow!("Token has expired"));
    }

    Ok(token_data.claims)
}

// Extract user ID from JWT token
pub fn extract_user_id(token: &str) -> Result<String> {
    let claims = validate_jwt(token)?;
    Ok(claims.sub)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;

    #[test]
    fn test_create_and_validate_jwt() {
        env::set_var("JWT_SECRET", "test-secret-key");
        
        let user_id = "123e4567-e89b-12d3-a456-426614174000";
        let token = create_jwt(user_id).unwrap();
        
        let claims = validate_jwt(&token).unwrap();
        assert_eq!(claims.sub, user_id);
    }

    #[test]
    fn test_extract_user_id() {
        env::set_var("JWT_SECRET", "test-secret-key");
        
        let user_id = "123e4567-e89b-12d3-a456-426614174000";
        let token = create_jwt(user_id).unwrap();
        
        let extracted_id = extract_user_id(&token).unwrap();
        assert_eq!(extracted_id, user_id);
    }
}