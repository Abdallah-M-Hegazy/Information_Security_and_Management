import javax.swing.*;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import java.awt.*;
import java.util.Random;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;

public class brute_furce extends javax.swing.JFrame {

    // Logger for tracking operations
    private static final Logger logger = Logger.getLogger(brute_furce.class.getName());

    // Password to be cracked
    private static final String TARGET_PASSWORD = "abcde";

    // Swing components
    private JPasswordField passwordField;
    private JTextArea passwordLogArea;
    private JPanel resultPanel;
    private JLabel resultLabel;

    // SwingWorker for the brute-force attack
    private SwingWorker<Void, String> worker;

    public brute_furce() {
        initComponents();
    }

    private void initComponents() {
        setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
        setTitle("LOGIN");
        setPreferredSize(new java.awt.Dimension(800, 500));

        // Configure logger
        Logger rootLogger = Logger.getLogger("");
        for (var handler : rootLogger.getHandlers()) {
            rootLogger.removeHandler(handler);
        }

        ConsoleHandler handler = new ConsoleHandler();
        handler.setLevel(Level.ALL);
        logger.addHandler(handler);
        logger.setLevel(Level.ALL);

        // Main panel using BorderLayout
        JPanel mainPanel = new JPanel(new BorderLayout());
        mainPanel.setBackground(new java.awt.Color(255, 255, 255));

        // Right panel (blue background)
        JPanel rightPanel = new JPanel();
        rightPanel.setBackground(new java.awt.Color(0, 222, 255));
        rightPanel.setPreferredSize(new java.awt.Dimension(400, 500));

        // Add components to the right panel
        passwordLogArea = new JTextArea();
        passwordLogArea.setEditable(false); // Make it read-only
        passwordLogArea.setFont(new Font("Monospaced", Font.PLAIN, 12)); // Use a monospaced font for better readability
        passwordLogArea.setBackground(new Color(255, 255, 255)); // Match the background color of the right panel
        passwordLogArea.setForeground(Color.black); // White text color
        JScrollPane scrollPane = new JScrollPane(passwordLogArea); // Add scroll bars

        JLabel titleLabel = new JLabel("Brute-force attack");
        titleLabel.setFont(new java.awt.Font("Showcard Gothic", 1, 24));
        titleLabel.setForeground(new java.awt.Color(255, 255, 255));
        JLabel copyrightLabel = new JLabel("copyright © login form All rights reserved");
        copyrightLabel.setFont(new java.awt.Font("Segoe UI Light", 0, 14));
        copyrightLabel.setForeground(new java.awt.Color(204, 204, 204));

        rightPanel.setLayout(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.weightx = 1;
        gbc.weighty = 1;
        gbc.fill = GridBagConstraints.BOTH;
        gbc.insets = new Insets(10, 10, 10, 10); // Padding
        rightPanel.add(scrollPane, gbc);

        gbc.gridy = 1;
        gbc.weighty = 0;
        rightPanel.add(titleLabel, gbc);

        gbc.gridy = 2;
        rightPanel.add(copyrightLabel, gbc);

        // Left panel (white background)
        JPanel leftPanel = new JPanel();
        leftPanel.setBackground(new java.awt.Color(255, 255, 255));
        leftPanel.setLayout(new GridBagLayout());

        // Add components to the left panel
        JLabel loginLabel = new JLabel("LOGIN");
        loginLabel.setFont(new java.awt.Font("Segoe UI", 1, 36));
        loginLabel.setForeground(new java.awt.Color(0, 222, 255));

        JLabel passwordLabel = new JLabel("Password");
        passwordLabel.setFont(new java.awt.Font("Segoe UI", 0, 14));
        passwordField = new JPasswordField(20);

        // Result panel (initially hidden)
        resultPanel = new JPanel();
        resultPanel.setBackground(Color.RED); // Red background for the result panel
        resultPanel.setVisible(false); // Initially hidden
        resultLabel = new JLabel();
        resultLabel.setFont(new Font("Segoe UI", Font.BOLD, 18));
        resultLabel.setForeground(Color.WHITE); // White text color
        resultPanel.add(resultLabel);

        // Add DocumentListener to the passwordField
        passwordField.getDocument().addDocumentListener(new DocumentListener() {
            @Override
            public void insertUpdate(DocumentEvent e) {
                checkPassword();
            }

            @Override
            public void removeUpdate(DocumentEvent e) {
                checkPassword();
            }

            @Override
            public void changedUpdate(DocumentEvent e) {
                checkPassword();
            }

            private void checkPassword() {
                // Get the password from the field
                String password = new String(passwordField.getPassword());

                // Check if the password length is 5 and contains only alphabetical letters
                if (password.length() == 5 && password.matches("[a-zA-Z]+")) {
                    // Validate the password
                    if (password.equals(TARGET_PASSWORD)) {
                        showResult("Login Successful!", Color.GREEN); // Green for success

                        // Stop the brute-force attack
                        if (worker != null && !worker.isDone()) {
                            worker.cancel(true); // Cancel the SwingWorker
                        }
                    } else {
                        showResult("Access Denied!", Color.RED); // Red for failure
                    }

                    // Clear the password field after the check (deferred using invokeLater)
                    SwingUtilities.invokeLater(() -> passwordField.setText(""));
                }
            }
        });

        gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.insets = new Insets(10, 10, 10, 10); // Padding
        leftPanel.add(loginLabel, gbc);

        gbc.gridy = 1;
        leftPanel.add(passwordLabel, gbc);

        gbc.gridy = 2;
        leftPanel.add(passwordField, gbc);

        gbc.gridy = 3;
        leftPanel.add(resultPanel, gbc);

        // Add right and left panels to the main panel
        mainPanel.add(rightPanel, BorderLayout.WEST);
        mainPanel.add(leftPanel, BorderLayout.CENTER);

        // Add the main panel to the frame
        add(mainPanel);

        pack();
        setLocationRelativeTo(null); // Center the window

        // Start brute-force attack in the background
        startBruteForceAttack();
    }

    private void showResult(String message, Color color) {
        resultLabel.setText(message);
        resultPanel.setBackground(color);
        resultPanel.setVisible(true);

        // Hide the result panel after 0.5 second
        Timer timer = new Timer(500, e -> {
            resultPanel.setVisible(false);
        });
        timer.setRepeats(false); // Ensure the timer runs only once
        timer.start();
    }

    private void startBruteForceAttack() {
        worker = new SwingWorker<>() {
            @Override
            protected Void doInBackground() throws Exception {
                Random random = new Random();
                while (true) {
                    // Check if the worker has been cancelled
                    if (isCancelled()) {
                        break;
                    }

                    // Generate a random 5-letter password
                    StringBuilder password = new StringBuilder();
                    for (int i = 0; i < 5; i++) {
                        char c = (char) (random.nextInt(26) + 'a'); // Random lowercase letter
                        password.append(c);
                    }

                    // Publish the generated password to the UI
                    publish(password.toString());

                    // Simulate a delay of 1 second between attempts
                    Thread.sleep(1000); // 1-second delay
                }
                return null;
            }

            @Override
            protected void process(java.util.List<String> chunks) {
                // Update the password field and log area with the latest generated password
                String password = chunks.get(chunks.size() - 1);
                passwordField.setText(password);
                passwordLogArea.append("Trying: " + password + "\n"); // Log the password
                passwordLogArea.setCaretPosition(passwordLogArea.getDocument().getLength()); // Auto-scroll to the bottom
            }

            @Override
            protected void done() {
                // Log when the brute-force attack is finished
                passwordLogArea.append("Brute-force attack finished.\n");
            }
        };

        worker.execute();
    }

}