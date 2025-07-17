use actix_web::{web, App, HttpServer, middleware::Logger};
use actix_cors::Cors;
use sqlx::PgPool;
use std::env;

mod models;
mod handlers;
mod services;
mod middleware;
mod utils;
mod database;
mod config;

use handlers::auth::{register, login, validate_token, logout, refresh_token};
use handlers::user::{get_profile, update_profile};
use handlers::accounts::{create_account, get_accounts, update_account, delete_account};
use handlers::transactions::{create_transaction, get_transactions, update_transaction, delete_transaction};
use handlers::loans::{create_loan, get_loans, update_loan, delete_loan};
use handlers::liabilities::{create_liability, get_liabilities, update_liability, delete_liability};
use middleware::auth::AuthMiddleware;
use config::Config;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize logger
    env_logger::init();
    
    // Load configuration
    let config = Config::from_env().expect("Failed to load configuration");
    
    // Create database connection pool
    let database_url = format!(
        "postgres://{}:{}@{}:{}/{}",
        config.database.user,
        config.database.password,
        config.database.host,
        config.database.port,
        config.database.name
    );
    
    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to database");
    
    // Run database migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run database migrations");
    
    log::info!("Starting Personal Manager Backend API on {}:{}", config.server.host, config.server.port);
    
    // Start HTTP server
    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);
        
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .app_data(web::Data::new(config.clone()))
            .wrap(cors)
            .wrap(Logger::default())
            .service(
                web::scope("/api")
                    .service(
                        web::scope("/auth")
                            .route("/register", web::post().to(register))
                            .route("/login", web::post().to(login))
                            .route("/validate", web::get().to(validate_token))
                            .route("/logout", web::post().to(logout))
                            .route("/refresh", web::post().to(refresh_token))
                    )
                    .service(
                        web::scope("/user")
                            .wrap(AuthMiddleware)
                            .route("/profile", web::get().to(get_profile))
                            .route("/profile", web::put().to(update_profile))
                    )
                    .service(
                        web::scope("/accounts")
                            .wrap(AuthMiddleware)
                            .route("", web::post().to(create_account))
                            .route("", web::get().to(get_accounts))
                            .route("/{id}", web::put().to(update_account))
                            .route("/{id}", web::delete().to(delete_account))
                    )
                    .service(
                        web::scope("/transactions")
                            .wrap(AuthMiddleware)
                            .route("", web::post().to(create_transaction))
                            .route("", web::get().to(get_transactions))
                            .route("/{id}", web::put().to(update_transaction))
                            .route("/{id}", web::delete().to(delete_transaction))
                    )
                    .service(
                        web::scope("/loans")
                            .wrap(AuthMiddleware)
                            .route("", web::post().to(create_loan))
                            .route("", web::get().to(get_loans))
                            .route("/{id}", web::put().to(update_loan))
                            .route("/{id}", web::delete().to(delete_loan))
                    )
                    .service(
                        web::scope("/liabilities")
                            .wrap(AuthMiddleware)
                            .route("", web::post().to(create_liability))
                            .route("", web::get().to(get_liabilities))
                            .route("/{id}", web::put().to(update_liability))
                            .route("/{id}", web::delete().to(delete_liability))
                    )
            )
            .route("/health", web::get().to(|| async { "OK" }))
    })
    .bind(format!("{}:{}", config.server.host, config.server.port))?
    .run()
    .await
}