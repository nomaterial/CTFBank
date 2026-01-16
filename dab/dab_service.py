from flask import Flask, request, jsonify
import os
import re
import subprocess
import tempfile

app = Flask(__name__)

@app.route('/api/execute_java', methods=['POST'])
def execute_java():
    data = request.json or {}
    java_code = data.get('code', '')

    if not java_code:
        return jsonify({'success': False, 'error': 'Code Java requis'}), 400

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            # Extraire le nom de la classe principale
            match = re.search(r'class\s+([A-Za-z_][A-Za-z0-9_]*)', java_code)
            class_name = match.group(1) if match else 'Payload'
            java_file = os.path.join(tmpdir, f'{class_name}.java')
            with open(java_file, 'w') as f:
                f.write(java_code)

            compile_result = subprocess.run(
                ['javac', java_file],
                capture_output=True,
                text=True,
                timeout=10
            )

            if compile_result.returncode != 0:
                return jsonify({
                    'success': False,
                    'error': 'Erreur de compilation',
                    'output': compile_result.stderr
                }), 400

            exec_result = subprocess.run(
                ['java', '-cp', tmpdir, class_name],
                capture_output=True,
                text=True,
                timeout=10
            )

            return jsonify({
                'success': True,
                'message': 'Code exécuté sur le DAB',
                'stdout': exec_result.stdout,
                'stderr': exec_result.stderr
            })

    except subprocess.TimeoutExpired:
        return jsonify({
            'success': False,
            'error': 'Timeout - Le code a pris trop de temps à s\'exécuter'
        }), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/replace_monitor', methods=['POST'])
def replace_monitor():
    data = request.json or {}
    new_content = data.get('content', '')

    if not new_content:
        return jsonify({'error': 'Contenu requis'}), 400

    try:
        monitor_path = '/opt/dab/monitor.sh'
        if os.path.exists(monitor_path):
            os.remove(monitor_path)

        with open(monitor_path, 'w') as f:
            f.write(new_content)

        os.chmod(monitor_path, 0o755)
        return jsonify({'success': True, 'message': 'Script remplacé'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
