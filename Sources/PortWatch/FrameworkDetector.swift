//
//  FrameworkDetector.swift
//  PortWatch
//
//  Detects frameworks from command line arguments
//

import Foundation

struct FrameworkDetector {
    static func detect(from command: String) -> Framework {
        let lowercased = command.lowercased()
        
        // JavaScript/TypeScript frameworks
        if lowercased.contains("vite") { return .vite }
        if lowercased.contains("astro") { return .astro }
        if lowercased.contains("next") { return .nextjs }
        if lowercased.contains("webpack") { return .webpack }
        
        // Python frameworks
        if lowercased.contains("fastapi") { return .fastapi }
        if lowercased.contains("uvicorn") && lowercased.contains("fastapi") { return .fastapi }
        if lowercased.contains("flask") { return .flask }
        if lowercased.contains("django") { return .django }
        if lowercased.contains("uvicorn") && !lowercased.contains("fastapi") { return .fastapi }
        if lowercased.contains("gunicorn") { return .flask }
        
        // Java frameworks
        if lowercased.contains("spring") { return .spring }
        
        // Ruby frameworks
        if lowercased.contains("rails") { return .rails }
        
        // AI/ML
        if lowercased.contains("llama-server") || lowercased.contains("llama.cpp") { return .llamaCpp }
        
        // Infrastructure
        if lowercased.contains("docker-proxy") || lowercased.contains("dockerd") { return .docker }
        if lowercased.contains("postgres") { return .postgres }
        if lowercased.contains("redis-server") { return .redis }
        if lowercased.contains("mongod") { return .mongodb }
        
        return .unknown
    }
}
