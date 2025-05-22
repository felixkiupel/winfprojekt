from flask import Flask, request, send_file, jsonify
import qrcode
from io import BytesIO

app = Flask(__name__)

@app.route('/api/qr/generate', methods=['POST'])
def generate_qr():
    """
    Erwartet JSON { "data": "<string zu enkodieren>" }
    Gibt ein PNG-Bild zurück.
    """
    payload = request.get_json(force=True)
    data = payload.get('data', '')
    if not data:
        return jsonify({'error': 'Kein data-Feld'}), 400

    # QR-Code erzeugen
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    # In Bytes puffern und zurücksenden
    buf = BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    return send_file(buf, mimetype='image/png', as_attachment=False, download_name='qrcode.png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
