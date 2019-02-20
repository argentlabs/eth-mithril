//
//  Int+Sequence.swift
//  web3swift
//
//  Created by Dmitry on 25/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

extension Range: IteratorProtocol where Bound == Int {
    /// Advances to the next element and returns it, or `nil` if no next element
    /// exists.
    ///
    /// Repeatedly calling this method returns, in order, all the elements of the
    /// underlying sequence. As soon as the sequence has run out of elements, all
    /// subsequent calls return `nil`.
    ///
    /// You must not call this method if any other copy of this iterator has been
    /// advanced with a call to its `next()` method.
    ///
    /// The following example shows how an iterator can be used explicitly to
    /// emulate a `for`-`in` loop. First, retrieve a sequence's iterator, and
    /// then call the iterator's `next()` method until it returns `nil`.
    ///
    ///     let numbers = [2, 3, 5, 7]
    ///     var numbersIterator = numbers.makeIterator()
    ///
    ///     while let num = numbersIterator.next() {
    ///         print(num)
    ///     }
    ///     // Prints "2"
    ///     // Prints "3"
    ///     // Prints "5"
    ///     // Prints "7"
    ///
    /// - Returns: The next element in the underlying sequence, if a next element
    ///   exists; otherwise, `nil`.
    public mutating func next() -> Bound? {
        guard lowerBound + 1 < upperBound else { return nil }
        self = lowerBound+1..<upperBound
        return lowerBound
    }
}

extension Int: Sequence {
    /// A type that provides the sequence's iteration interface and
    /// encapsulates its iteration state.
    public typealias Iterator = Range<Int>
    /// Returns an iterator over the elements of this sequence.
    public func makeIterator() -> Range<Int> {
        return -1..<self
    }
}
