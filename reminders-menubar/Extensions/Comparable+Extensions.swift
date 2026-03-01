extension Comparable {
    func constrainedTo(min lower: Self, max upper: Self) -> Self {
        min(max(self, lower), upper)
    }
}
