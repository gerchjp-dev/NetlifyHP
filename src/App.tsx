import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { HelmetProvider } from 'react-helmet-async';
import { LanguageProvider } from './contexts/LanguageContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { AuthProvider } from './contexts/AuthContext';
import { Home } from './pages/Home';
import { Login } from './pages/Login';
import { Admin } from './pages/Admin';
import BlogPost from './pages/BlogPost';

const router = createBrowserRouter(
  [
    {
      path: '/',
      element: <Home />,
    },
    {
      path: '/login',
      element: <Login />,
    },
    {
      path: '/admin',
      element: <Admin />,
    },
    {
      path: '/blog/:id',
      element: <BlogPost />,
    },
  ],
  {
    future: {
      v7_startTransition: true,
      v7_relativeSplatPath: true,
      v7_fetcherPersist: true,
      v7_normalizeFormMethod: true,
      v7_partialHydration: true,
      v7_skipActionErrorRevalidation: true,
    },
  }
);

function App() {
  return (
    <HelmetProvider>
      <AuthProvider>
        <LanguageProvider>
          <ThemeProvider>
            <RouterProvider router={router} />
          </ThemeProvider>
        </LanguageProvider>
      </AuthProvider>
    </HelmetProvider>
  );
}

export default App;
