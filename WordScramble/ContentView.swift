//
//  ContentView.swift
//  WordScramble
//
//  Created by EDSON FELIPE VASCONCELOS on 18/04/23.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var score = 0
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @FocusState private var focusedField: Bool
    @FocusState private var focusedScreen: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    VStack {
                        TextField("Enter your word", text: $newWord)
                            .foregroundColor(.primary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField)
                            .onAppear {
                                self.focusedField = true
                            }
                            .onSubmit {
                                addNewWord()
                                focusedField = true
                            }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    List {
                        Section("Correct words") {
                            ForEach(usedWords, id: \.self) { word in
                                HStack {
                                    Image(systemName: "\(word.count).circle")
                                    Text("\(word)")
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .onSubmit(addNewWord)
                    .onAppear(perform: startGame)
                    .cornerRadius(15)
                    .opacity(0.5)
                    .toolbar {
                        Button("Restart", action: startGame)
                    }
                    .alert(errorTitle, isPresented: $showingError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(errorMessage)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Text("Your score is \(score)")
                            .padding()
                            .font(.headline)
                            .frame(width: 175, height: 100)
                            .foregroundColor(Color.yellow)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .padding()
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle(rootWord)
        }
        .focused($focusedScreen)
        .onTapGesture {
            self.focusedScreen = true
            self.focusedField = false
        }

    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // exit if the remaining string is empty
        guard answer.count > 2 && answer != rootWord else { return }
                
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        
        score += answer.count
        newWord = ""
    }
    
    func startGame() {
        score = 0
        usedWords.removeAll()
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                
                // 4. Pick one random word, or use "silkworm" as a sensible default
                rootWord = allWords.randomElement() ?? "silkworm"
                
                // If we are here everything has worked, so we can exit
                return
            }
        }
        // If were are *here* then there was a problem – trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                newWord = ""

                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        newWord = ""

        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        newWord = ""
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
