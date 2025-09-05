// Updated file upload component with Lambda function URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

class FileUploader {
    constructor() {
        this.apiBaseUrl = API_BASE_URL;
    }

    /**
     * Upload a file to the backend
     * @param {File} file - The file to upload
     * @param {Function} onProgress - Progress callback function
     * @returns {Promise<Object>} Upload response
     */
    async uploadFile(file, onProgress = null) {
        try {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('fileName', file.name);

            const response = await fetch(`${this.apiBaseUrl}/upload`, {
                method: 'POST',
                body: formData,
                headers: {
                    // Don't set Content-Type for FormData - browser will set it with boundary
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            return result;
        } catch (error) {
            console.error('Upload error:', error);
            throw error;
        }
    }

    /**
     * Upload file as base64 (alternative method)
     * @param {File} file - The file to upload
     * @returns {Promise<Object>} Upload response
     */
    async uploadFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            
            reader.onload = async (e) => {
                try {
                    const base64Data = e.target.result.split(',')[1]; // Remove data:type;base64, prefix
                    
                    const response = await fetch(`${this.apiBaseUrl}/upload`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            file: base64Data,
                            fileName: file.name,
                            fileType: file.type
                        })
                    });

                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }

                    const result = await response.json();
                    resolve(result);
                } catch (error) {
                    reject(error);
                }
            };
            
            reader.onerror = () => reject(new Error('Failed to read file'));
            reader.readAsDataURL(file);
        });
    }

    /**
     * Process an uploaded resume
     * @param {string} fileKey - The S3 key of the uploaded file
     * @param {string} processingType - Type of processing ('extract' or 'analyze')
     * @returns {Promise<Object>} Processing response
     */
    async processResume(fileKey, processingType = 'extract') {
        try {
            const response = await fetch(`${this.apiBaseUrl}/process`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    fileKey: fileKey,
                    processingType: processingType
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            return result;
        } catch (error) {
            console.error('Processing error:', error);
            throw error;
        }
    }

    /**
     * Check backend health
     * @returns {Promise<Object>} Health status
     */
    async checkHealth() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/health`);
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Health check error:', error);
            throw error;
        }
    }

    /**
     * Handle file upload with progress and error handling
     * @param {File} file - The file to upload
     * @param {Object} callbacks - Object containing callback functions
     */
    async handleFileUpload(file, callbacks = {}) {
        const {
            onStart = () => {},
            onProgress = () => {},
            onSuccess = () => {},
            onError = () => {}
        } = callbacks;

        try {
            onStart();

            // Validate file
            if (!this.validateFile(file)) {
                throw new Error('Invalid file type or size');
            }

            // Upload file
            const uploadResult = await this.uploadFile(file, onProgress);
            
            if (uploadResult.error) {
                throw new Error(uploadResult.error);
            }

            // Process the uploaded resume
            const processResult = await this.processResume(uploadResult.key);
            
            onSuccess({
                upload: uploadResult,
                processing: processResult
            });

            return {
                upload: uploadResult,
                processing: processResult
            };

        } catch (error) {
            onError(error);
            throw error;
        }
    }

    /**
     * Validate file type and size
     * @param {File} file - The file to validate
     * @returns {boolean} Whether the file is valid
     */
    validateFile(file) {
        const allowedTypes = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (!allowedTypes.includes(file.type)) {
            console.error('Invalid file type:', file.type);
            return false;
        }

        if (file.size > maxSize) {
            console.error('File too large:', file.size);
            return false;
        }

        return true;
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FileUploader;
} else if (typeof window !== 'undefined') {
    window.FileUploader = FileUploader;
}

export default FileUploader;