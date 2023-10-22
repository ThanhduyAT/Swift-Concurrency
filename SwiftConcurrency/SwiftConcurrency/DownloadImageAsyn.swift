//
//  DownloadImageAsyn.swift
//  SwiftConcurrency
//
//  Created by Thanh Duy on 21/10/2023.
//

import SwiftUI
import Combine

class DownloadImageAsynImageLoader {
    let url = URL(string: "https://picsum.photos/200")!
    
    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else  {
                return nil
            }
        return image
    }
    
    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completionHandler(image, nil)
        }
        .resume()
    }
    
    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError({ $0 })
            .eraseToAnyPublisher()
    }
    
    func downloadWithAsync() async throws -> UIImage? {
        if #available(iOS 15.0, *) {
            do {
                
                let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
                return handleResponse(data: data, response: response)
            } catch {
                throw error
            }
        } else {
            return nil
        }
    }
}

class DownloadImageAsynViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    let loader = DownloadImageAsynImageLoader()
    var cancellables = Set<AnyCancellable>()
    
    func fetchData() async {
        /*
//        loader.downloadWithEscaping { [weak self] image, error in
//            if let image = image {
//                DispatchQueue.main.async {
//                    self?.image = image
//                }
//            }
//        }
//        loader.downloadWithCombine()
//            .receive(on: DispatchQueue.main)
//            .sink { _ in
//
//            } receiveValue: { image in
//                self.image = image
//            }
//            .store(in: &cancellables)
         */
        let image = try? await loader.downloadWithAsync()
        await MainActor.run {
            self.image = image
        }
    }
}

struct DownloadImageAsyn: View {
    @StateObject private var viewModel = DownloadImageAsynViewModel()
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchData()
            }
            
        }
    }
}

struct DownloadImageAsyn_Previews: PreviewProvider {
    static var previews: some View {
        DownloadImageAsyn()
    }
}
