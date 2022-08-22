import Fluent
import FluentMySQLDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    
    
    let appConfig = AppConfig()
    app.http.server.configuration.port = appConfig.listenOnPort
    
    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = appConfig.certificateVerification
    
    app.databases.use(.mysql(
        hostname: appConfig.database.hostname,
        username: appConfig.database.username,
        password: appConfig.database.password,
        database: appConfig.database.database,
        tlsConfiguration: tls
    ), as: .mysql)
    
    

    // register routes
    try routes(app, appConfig)
}
