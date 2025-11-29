public enum Distribution: Sendable {
    case fill
    case fillEqually
    case fillProportionally
}

extension Distribution: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fill:
            return "fill"
        case .fillEqually:
            return "fillEqually"
        case .fillProportionally:
            return "fillProportionally"
        }
    }
}
