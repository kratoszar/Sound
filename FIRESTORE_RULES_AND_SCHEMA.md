# Firestore: esquema, índices y reglas sugeridas para SoundWave

## 1. Colecciones y subcolecciones

- `users/{userId}`
  - Campos:
    - `name`: string
    - `email`: string
    - `avatar`: string | null
    - `followers`: number
    - `following`: number
    - `createdAt`: timestamp
  - Subcolecciones:
    - `followers/{followerUserId}`
      - `createdAt`: timestamp
    - `following/{targetUserId}`
      - `createdAt`: timestamp
    - `history/{historyId}`
      - `trackId`: string
      - `playedAt`: timestamp
      - `title`: string
      - `artist`: string
      - `coverUrl`: string | null
      - `audioUrl`: string

- `tracks/{trackId}`
  - Campos:
    - `title`: string
    - `artist`: string
    - `userId`: string
    - `audioUrl`: string
    - `coverUrl`: string | null
    - `likes`: number
    - `duration`: number (milisegundos)
    - `createdAt`: timestamp
  - Subcolecciones:
    - `likes/{userId}`
      - `createdAt`: timestamp

- `videos/{videoId}`
  - Campos:
    - `userId`: string
    - `videoUrl`: string
    - `caption`: string
    - `likes`: number
    - `createdAt`: timestamp
  - Subcolecciones:
    - `likes/{userId}`
      - `createdAt`: timestamp
    - `comments/{commentId}`
      - `userId`: string
      - `text`: string
      - `createdAt`: timestamp

- `playlists/{playlistId}`
  - Campos:
    - `userId`: string
    - `title`: string
    - `tracks`: string[] (ids de tracks)
    - `createdAt`: timestamp

## 2. Índices recomendados

Configura índices compuestos/simples en la consola de Firestore:

- `tracks`
  - Orden: `createdAt` desc
- `videos`
  - Orden: `createdAt` desc
- `users/{userId}/history`
  - Orden: `playedAt` desc
- `users/{userId}/followers`
  - Orden: `createdAt` desc (opcional)
- `users/{userId}/following`
  - Orden: `createdAt` desc (opcional)
- `videos/{videoId}/comments`
  - Orden: `createdAt` desc

## 3. Borrador de reglas de seguridad (ejemplo)

Adapta este borrador en tu panel de Firestore (`Rules`), verificando bien los paths:

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // users
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false;

      // followers / following
      match /followers/{followerId} {
        allow read: if isSignedIn();
        allow write: if request.auth.uid == followerId;
      }

      match /following/{targetId} {
        allow read: if isSignedIn();
        allow write: if isOwner(userId);
      }

      // history
      match /history/{historyId} {
        allow read, write: if isOwner(userId);
      }
    }

    // tracks públicos
    match /tracks/{trackId} {
      allow read: if true;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isSignedIn() && resource.data.userId == request.auth.uid;

      // likes como subcolección
      match /likes/{likeUserId} {
        allow read: if true;
        allow write: if isSignedIn() && likeUserId == request.auth.uid;
      }
    }

    // videos públicos
    match /videos/{videoId} {
      allow read: if true;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isSignedIn() && resource.data.userId == request.auth.uid;

      match /likes/{userId} {
        allow read: if true;
        allow write: if isSignedIn() && userId == request.auth.uid;
      }

      match /comments/{commentId} {
        allow read: if true;
        allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
        allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
      }
    }

    // playlists del usuario
    match /playlists/{playlistId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
  }
}
```

Usa esto como base y ajusta según tus necesidades de negocio y de seguridad.

