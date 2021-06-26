//
//  AllUsersService.swift
//  Many-to-many-call
//
//  Created by usama farooq on 14/06/2021.
//

import Foundation

typealias AllUserComplition = ((Result<AllUsersResponse, Error>) -> Void)

protocol AllUserStoreAble {
    func fetchUsers(with request: AllUserRequest, complition: @escaping AllUserComplition)
}

class AllUsersService:BaseDataStore, AllUserStoreAble {
    
    let translator: ObjectTranslator
    
    init(service: Service, translator: ObjectTranslator = ObjectTranslation()) {
        self.translator = translator
        super.init(service: service)
    }
    
    
    func fetchUsers(with request: AllUserRequest, complition: @escaping AllUserComplition) {
        service.post(request: request) {[weak self] (result) in
            guard let self = self else {return}
            switch result {
            case .success(let data):
                self.translate(data: data, complition: complition)
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }
    private func translate(data: Data, complition: AllUserComplition) {
        do {
            let response: AllUsersResponse = try translator.decodeObject(data: data)
            complition(.success(response))
        }
        catch {
            complition(.failure(error))
        }
    }
    
}
