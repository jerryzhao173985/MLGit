#!/usr/bin/env python3
"""
Test Python file to verify syntax highlighting
"""

def hello_world():
    """Print hello world"""
    print("Hello, World!")
    
    # This is a comment
    numbers = [1, 2, 3, 4, 5]
    for num in numbers:
        if num % 2 == 0:
            print(f"{num} is even")
        else:
            print(f"{num} is odd")

class TestClass:
    def __init__(self):
        self.name = "Test"
    
    def greet(self):
        return f"Hello from {self.name}"

if __name__ == "__main__":
    hello_world()
    test = TestClass()
    print(test.greet())