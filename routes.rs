use axum::{
    routing::{get, post, put, delete},
    Router,
};

use crate::handlers::auth::{signup, signin, validate, logout, refresh_token};
use crate::services::database::DbPool;

pub fn auth_routes() -> Router<DbPool> {
    Router::new()
        .route("/signup", post(signup))
        .route("/signin", post(signin))
        .route("/validate", get(validate))
        .route("/logout", post(logout))
        .route("/refresh", post(refresh_token))
}

// Example of how to structure your main.rs router
pub fn create_router(pool: DbPool) -> Router {
    Router::new()
        .nest("/auth", auth_routes())
        .route("/health", get(|| async { "OK" }))
        .with_state(pool)
}

/* 
Add this to your main.rs:

use axum::{
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::init();

    // Database connection
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to database");

    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    // Create application
    let app = Router::new()
        .nest("/api/auth", auth_routes())
        .route("/health", get(|| async { "OK" }))
        .layer(CorsLayer::permissive())
        .with_state(pool);

    // Run server
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    println!("Server running on http://{}", addr);
    
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
*/