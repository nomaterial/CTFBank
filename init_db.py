import sqlite3
import os

db_path = 'bank.db'

# Supprimer la base si elle existe déjà
if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Créer la table users
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT,
        role TEXT DEFAULT 'client',
        balance REAL DEFAULT 0.0
    )
''')

# Insérer les utilisateurs
users = [
    ('Admin', 'M0tD3P4ss3F4cil3', 'admin@bank.ctf', 'admin', 1000000.0),
    # Informaticien (accès spécial - visible sur dashboard admin)
    ('Jean.Admin', 'Info2024!', 'jean.admin@bank.ctf', 'informaticien', 0.0),
    # Contacts internes (visibles sur dashboard admin)
    ('Marie.RH', 'RH_Secure123', 'marie.rh@bank.ctf', 'rh', 0.0),
    ('Pierre.Comptable', 'Compta456!', 'pierre.comptable@bank.ctf', 'comptable', 0.0),
    ('Sophie.Securite', 'Secu789!', 'sophie.securite@bank.ctf', 'securite', 0.0),
    # Clients normaux
    ('Jean.Dupont', 'Client123!', 'jean.dupont@email.com', 'client', 5000.0),
    ('Marie.Martin', 'SecurePass456', 'marie.martin@email.com', 'client', 12000.0),
    ('Pierre.Durand', 'MyPass789', 'pierre.durand@email.com', 'client', 800.0),
    ('Sophie.Bernard', 'Pass2024!', 'sophie.bernard@email.com', 'client', 2500.0),
    ('Paul.Lefebvre', 'Paul2024!', 'paul.lefebvre@email.com', 'client', 3500.0),
    ('Claire.Moreau', 'Claire123!', 'claire.moreau@email.com', 'client', 9800.0),
]

cursor.executemany(
    'INSERT OR REPLACE INTO users (username, password, email, role, balance) VALUES (?, ?, ?, ?, ?)',
    users
)

# Créer une table pour les logs (utilisée pour le CTF)
cursor.execute('''
    CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
''')

conn.commit()
conn.close()

print("✅ Base de données initialisée avec succès!")
print(f"   Base de données créée: {os.path.abspath(db_path)}")

