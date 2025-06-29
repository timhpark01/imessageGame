import UIKit
import Messages

// MARK: - Game Protocol
protocol Game {
    var title: String { get }
    var emoji: String { get }
    var description: String { get }
    func createViewController() -> UIViewController
}

// MARK: - Main Messages View Controller
class MessagesViewController: MSMessagesAppViewController {
    
    var currentGameViewController: UIViewController?
    let gameManager = GameManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showGameMenu()
    }
    
    func showGameMenu() {
        // Remove current game if any
        if let currentGame = currentGameViewController {
            currentGame.willMove(toParent: nil)
            currentGame.view.removeFromSuperview()
            currentGame.removeFromParent()
            currentGameViewController = nil
        }
        
        // Show game menu
        let menuVC = GameMenuViewController()
        menuVC.delegate = self
        menuVC.games = gameManager.availableGames
        
        addChild(menuVC)
        view.addSubview(menuVC.view)
        menuVC.view.frame = view.bounds
        menuVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        menuVC.didMove(toParent: self)
    }
    
    func showGame(_ game: Game) {
        // Remove menu
        if let menuVC = children.first(where: { $0 is GameMenuViewController }) {
            menuVC.willMove(toParent: nil)
            menuVC.view.removeFromSuperview()
            menuVC.removeFromParent()
        }
        
        // Show selected game
        let gameVC = game.createViewController()
        
        // If it's a GuessNumberViewController, set the messages delegate
        if let guessGameVC = gameVC as? GuessNumberViewController {
            guessGameVC.messagesDelegate = self
        }
        
        currentGameViewController = gameVC
        addChild(gameVC)
        view.addSubview(gameVC.view)
        gameVC.view.frame = view.bounds
        gameVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gameVC.didMove(toParent: self)
    }
    
    // MARK: - Messages App Lifecycle
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        
        // Check if we need to load a specific game state
        if let message = conversation.selectedMessage,
           let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let gameType = components.queryItems?.first(where: { $0.name == "gameType" })?.value {
            
            switch gameType {
            case "numberGuess":
                let game = NumberGuessGame()
                showGame(game)
                if let guessGameVC = currentGameViewController as? GuessNumberViewController {
                    guessGameVC.loadGameState(from: components)
                }
            default:
                break
            }
        }
    }
}

// MARK: - Game Menu Delegate
extension MessagesViewController: GameMenuDelegate {
    func didSelectGame(_ game: Game) {
        showGame(game)
    }
    
    func didRequestBackToMenu() {
        showGameMenu()
    }
}

// MARK: - Game Menu View Controller
protocol GameMenuDelegate: AnyObject {
    func didSelectGame(_ game: Game)
    func didRequestBackToMenu()
}

class GameMenuViewController: UIViewController {
    weak var delegate: GameMenuDelegate?
    var games: [Game] = []
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Create UI elements programmatically
        let titleLabel = UILabel()
        let subtitleLabel = UILabel()
        let tableView = UITableView()
        
        // Configure title
        titleLabel.text = "🎮 Game Hub"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        
        // Configure subtitle
        subtitleLabel.text = "Choose a game to play with friends!"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GameMenuCell.self, forCellReuseIdentifier: "GameCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        
        // Add to view
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)
        
        // Set up constraints
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.tableView = tableView
    }
}

// MARK: - Table View Data Source & Delegate
extension GameMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameMenuCell
        let game = games[indexPath.row]
        cell.configure(with: game)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let game = games[indexPath.row]
        delegate?.didSelectGame(game)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - Game Menu Cell
class GameMenuCell: UITableViewCell {
    let emojiLabel = UILabel()
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let chevronImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    func setupCell() {
        backgroundColor = UIColor.clear
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        // Configure emoji label
        emojiLabel.font = UIFont.systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        
        // Configure title label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = UIColor.label
        
        // Configure description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.secondaryLabel
        descriptionLabel.numberOfLines = 2
        
        // Configure chevron
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor.systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(chevronImageView)
        
        // Set up constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            
            emojiLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            emojiLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 50),
            
            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -10),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -15),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with game: Game) {
        emojiLabel.text = game.emoji
        titleLabel.text = game.title
        descriptionLabel.text = game.description
    }
}

// MARK: - Game Manager
class GameManager {
    var availableGames: [Game] {
        return [
            NumberGuessGame()
            // Add more games here in the future
        ]
    }
}

// MARK: - Number Guess Game Implementation
struct NumberGuessGame: Game {
    var title: String { "Guess the Number" }
    var emoji: String { "🎯" }
    var description: String { "Guess the secret number between 1-100 in 7 tries!" }
    
    func createViewController() -> UIViewController {
        return GuessNumberViewController()
    }
}

// MARK: - Guess Number View Controller
class GuessNumberViewController: UIViewController {
    weak var messagesDelegate: MessagesViewController?
    
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var guessTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var attemptsLabel: UILabel!
    @IBOutlet weak var newGameButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var targetNumber: Int = 0
    var attempts: Int = 0
    var maxAttempts: Int = 7
    var gameActive: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startNewGame()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Create UI elements programmatically
        let gameView = UIView()
        let titleLabel = UILabel()
        let instructionLabel = UILabel()
        let guessTextField = UITextField()
        let submitButton = UIButton()
        let resultLabel = UILabel()
        let attemptsLabel = UILabel()
        let newGameButton = UIButton()
        let backButton = UIButton()
        
        // Setup title
        titleLabel.text = "🎯 Guess the Number!"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        // Setup instruction
        instructionLabel.text = "I'm thinking of a number between 1 and 100"
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        
        // Setup text field
        guessTextField.placeholder = "Enter your guess"
        guessTextField.textAlignment = .center
        guessTextField.keyboardType = .numberPad
        guessTextField.borderStyle = .roundedRect
        guessTextField.font = UIFont.systemFont(ofSize: 18)
        guessTextField.delegate = self
        
        // Setup submit button
        submitButton.setTitle("Submit Guess", for: .normal)
        submitButton.backgroundColor = UIColor.systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Setup result label
        resultLabel.text = ""
        resultLabel.font = UIFont.systemFont(ofSize: 18)
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        
        // Setup attempts label
        attemptsLabel.font = UIFont.systemFont(ofSize: 14)
        attemptsLabel.textAlignment = .center
        attemptsLabel.textColor = UIColor.systemGray
        
        // Setup new game button
        newGameButton.setTitle("New Game", for: .normal)
        newGameButton.backgroundColor = UIColor.systemGreen
        newGameButton.setTitleColor(.white, for: .normal)
        newGameButton.layer.cornerRadius = 8
        newGameButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        newGameButton.isHidden = true
        
        // Setup back button
        backButton.setTitle("← Back to Games", for: .normal)
        backButton.backgroundColor = UIColor.systemGray5
        backButton.setTitleColor(.label, for: .normal)
        backButton.layer.cornerRadius = 8
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        // Add targets
        submitButton.addTarget(self, action: #selector(submitGuess), for: .touchUpInside)
        newGameButton.addTarget(self, action: #selector(startNewGame), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backToMenu), for: .touchUpInside)
        
        // Add to view
        view.addSubview(gameView)
        gameView.addSubview(titleLabel)
        gameView.addSubview(instructionLabel)
        gameView.addSubview(guessTextField)
        gameView.addSubview(submitButton)
        gameView.addSubview(resultLabel)
        gameView.addSubview(attemptsLabel)
        gameView.addSubview(newGameButton)
        gameView.addSubview(backButton)
        
        // Store references
        self.gameView = gameView
        self.titleLabel = titleLabel
        self.instructionLabel = instructionLabel
        self.guessTextField = guessTextField
        self.submitButton = submitButton
        self.resultLabel = resultLabel
        self.attemptsLabel = attemptsLabel
        self.newGameButton = newGameButton
        self.backButton = backButton
        
        // Setup constraints
        setupConstraints()
    }
    
    func setupConstraints() {
        gameView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        guessTextField.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        attemptsLabel.translatesAutoresizingMaskIntoConstraints = false
        newGameButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Game view
            gameView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gameView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gameView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            gameView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Back button
            backButton.topAnchor.constraint(equalTo: gameView.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: gameView.leadingAnchor),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            backButton.widthAnchor.constraint(equalToConstant: 140),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: gameView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: gameView.trailingAnchor),
            
            // Instruction
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            instructionLabel.leadingAnchor.constraint(equalTo: gameView.leadingAnchor),
            instructionLabel.trailingAnchor.constraint(equalTo: gameView.trailingAnchor),
            
            // Text field
            guessTextField.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 25),
            guessTextField.centerXAnchor.constraint(equalTo: gameView.centerXAnchor),
            guessTextField.widthAnchor.constraint(equalToConstant: 150),
            guessTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Submit button
            submitButton.topAnchor.constraint(equalTo: guessTextField.bottomAnchor, constant: 15),
            submitButton.centerXAnchor.constraint(equalTo: gameView.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 120),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Result label
            resultLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: gameView.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: gameView.trailingAnchor),
            
            // Attempts label
            attemptsLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 10),
            attemptsLabel.leadingAnchor.constraint(equalTo: gameView.leadingAnchor),
            attemptsLabel.trailingAnchor.constraint(equalTo: gameView.trailingAnchor),
            
            // New game button
            newGameButton.topAnchor.constraint(equalTo: attemptsLabel.bottomAnchor, constant: 20),
            newGameButton.centerXAnchor.constraint(equalTo: gameView.centerXAnchor),
            newGameButton.widthAnchor.constraint(equalToConstant: 120),
            newGameButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func startNewGame() {
        targetNumber = Int.random(in: 1...100)
        attempts = 0
        gameActive = true
        
        instructionLabel.text = "I'm thinking of a number between 1 and 100"
        resultLabel.text = ""
        guessTextField.text = ""
        guessTextField.isEnabled = true
        submitButton.isEnabled = true
        newGameButton.isHidden = true
        
        updateAttemptsLabel()
        createGameMessage()
    }
    
    @objc func submitGuess() {
        guard let guessText = guessTextField.text,
              let guess = Int(guessText),
              guess >= 1 && guess <= 100,
              gameActive else {
            showAlert(title: "Invalid Input", message: "Please enter a number between 1 and 100")
            return
        }
        
        attempts += 1
        guessTextField.text = ""
        
        if guess == targetNumber {
            resultLabel.text = "🎉 Congratulations! You guessed it!"
            resultLabel.textColor = UIColor.systemGreen
            endGame(won: true)
        } else if attempts >= maxAttempts {
            resultLabel.text = "😔 Game Over! The number was \(targetNumber)"
            resultLabel.textColor = UIColor.systemRed
            endGame(won: false)
        } else {
            let hint = guess < targetNumber ? "📈 Too low!" : "📉 Too high!"
            resultLabel.text = hint
            resultLabel.textColor = UIColor.systemOrange
            updateAttemptsLabel()
        }
        
        createGameMessage()
    }
    
    @objc func backToMenu() {
        messagesDelegate?.didRequestBackToMenu()
    }
    
    func endGame(won: Bool) {
        gameActive = false
        guessTextField.isEnabled = false
        submitButton.isEnabled = false
        newGameButton.isHidden = false
        updateAttemptsLabel()
    }
    
    func updateAttemptsLabel() {
        let remaining = maxAttempts - attempts
        attemptsLabel.text = gameActive ? "Attempts remaining: \(remaining)" : "Game finished in \(attempts) attempts"
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func createGameMessage() {
        guard let conversation = messagesDelegate?.activeConversation else { return }
        
        let message = MSMessage()
        let template = MSMessageTemplateLayout()
        
        template.caption = gameActive ? "Guess the Number - \(attempts)/\(maxAttempts) attempts" : "Game Finished!"
        template.subcaption = gameActive ? "Can you guess the number?" : resultLabel.text
        template.image = createGameImage()
        
        message.layout = template
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "gameType", value: "numberGuess"),
            URLQueryItem(name: "target", value: String(targetNumber)),
            URLQueryItem(name: "attempts", value: String(attempts)),
            URLQueryItem(name: "active", value: String(gameActive))
        ]
        message.url = components.url
        
        conversation.insert(message) { error in
            if let error = error {
                print("Error inserting message: \(error)")
            }
        }
    }
    
    func createGameImage() -> UIImage {
        let size = CGSize(width: 300, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()!
        
        UIColor.systemBlue.withAlphaComponent(0.1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        let titleText = "🎯 Guess the Number"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.label
        ]
        
        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (size.width - titleSize.width) / 2, y: 30, width: titleSize.width, height: titleSize.height)
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        
        let statusText = gameActive ? "Attempts: \(attempts)/\(maxAttempts)" : "Game Complete!"
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let statusSize = statusText.size(withAttributes: statusAttributes)
        let statusRect = CGRect(x: (size.width - statusSize.width) / 2, y: 80, width: statusSize.width, height: statusSize.height)
        statusText.draw(in: statusRect, withAttributes: statusAttributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func loadGameState(from components: URLComponents) {
        guard let queryItems = components.queryItems else { return }
        
        for item in queryItems {
            switch item.name {
            case "target":
                if let value = item.value, let number = Int(value) {
                    targetNumber = number
                }
            case "attempts":
                if let value = item.value, let count = Int(value) {
                    attempts = count
                }
            case "active":
                if let value = item.value {
                    gameActive = Bool(value) ?? false
                }
            default:
                break
            }
        }
        
        updateAttemptsLabel()
        
        if !gameActive {
            endGame(won: false)
        }
    }
}

// MARK: - Text Field Delegate
extension GuessNumberViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitGuess()
        return true
    }
}
