import React, { useState, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import axios from 'axios';

function ProductDetail() {
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { id } = useParams();

  const API_URL = import.meta.env.VITE_API_URL;

  useEffect(() => {
    console.log('API_URL:', API_URL); // Debug: Verify API_URL
    const fetchProduct = async () => {
      try {
        const response = await axios.get(`/api/products/${id}`);
        console.log('Product response:', response.data); // Debug: Log response
        if (!response.data.success) throw new Error('Product not found');
        setProduct(response.data.data);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching product details:', error);
        setError(`Product not found or error loading details: ${error.message}`);
        setLoading(false);
      }
    };

    fetchProduct();
  }, [id, API_URL]);

  if (loading) {
    return (
      <div className="text-center py-5">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading product details...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="alert alert-danger">
        <p>{error}</p>
        <Link to="/" className="btn btn-primary">Back to Search</Link>
      </div>
    );
  }

  return (
    <div className="card shadow">
      <div className="card-header bg-primary text-white">
        <h2 className="mb-0">{product.name}</h2>
      </div>
      <div className="card-body">
        <div className="row">
          <div className="col-md-8">
            <h4>Product Information</h4>
            <p className="lead">This is a detailed view of the selected product.</p>
            {product.description && (
              <p>{product.description}</p>
            )}
          </div>
          <div className="col-md-4">
            <div className="card mb-3">
              <div className="card-body">
                <h6>Product Details</h6>
                <p><strong>ID:</strong> {product.id}</p>
                <p><strong>Name:</strong> {product.name}</p>
                <p><strong>Category:</strong> {product.category || 'N/A'}</p>
                <p><strong>Price:</strong> {product.price ? `$${product.price.toFixed(2)}` : 'N/A'}</p>
              </div>
            </div>
          </div>
        </div>

        <hr/>

        <div className="row">
          <div className="col-md-6">
            <h5>Security Note</h5>
            <div className="alert alert-info">
              <p><strong>Secure Endpoint:</strong> This product detail page uses parameterized queries and is not vulnerable to SQL injection.</p>
              <p>The main search page demonstrates the vulnerability for educational purposes.</p>
            </div>
          </div>
        </div>
      </div>
      <div className="card-footer">
        <Link to="/" className="btn btn-secondary">Back to Search</Link>
      </div>
    </div>
  );
}

export default ProductDetail;