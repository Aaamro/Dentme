const authorizeRole = (requiredRole) => {
    return (req, res, next) => {
      const role = req.headers['current-role'];
      if (role !== requiredRole) {
        return res.status(403).json({ error: `Access denied. Only ${requiredRole}s can perform this action.` });
      }
      next();
    };
  };
  
  module.exports = authorizeRole;
  