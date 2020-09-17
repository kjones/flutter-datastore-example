// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "d56528714da04741e0b1864a4666658a"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Todo.self)
  }
}