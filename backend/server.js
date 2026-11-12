const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

// ===== CRON PARA REACTIVAR SANCIONES VENCIDAS =====
const cron = require('node-cron');

// ===== FIREBASE ADMIN =====
const admin = require('firebase-admin');
const { getApps, initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const serviceAccount = process.env.FIREBASE_KEY
    ? JSON.parse(process.env.FIREBASE_KEY)
    : require('./firebase-key.json');

if (getApps().length === 0) {
    initializeApp({
        credential: cert(serviceAccount)
    });
}
console.log('>>> 🔥 Firebase Admin inicializado');
console.log('>>> 🔥 Firebase Admin inicializado');

const app = express();
const port = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// ===== CONEXIÓN A POSTGRESQL =====
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

pool.query('SELECT NOW()')
    .then(() => console.log('>>> ✅ Conexión a PostgreSQL OK'))
    .catch(err => console.error('>>> ❌ Error de conexión:', err.message));

// ===== CRON PARA REACTIVAR SANCIONES VENCIDAS =====
cron.schedule('0 * * * *', async () => {
    try {
        const result = await pool.query(
            `UPDATE usuarios 
             SET estado_cuenta = 'activo',
                 motivo_sancion = NULL,
                 fecha_fin_sancion = NULL
             WHERE estado_cuenta = 'suspendido' 
               AND fecha_fin_sancion IS NOT NULL 
               AND fecha_fin_sancion < NOW()
             RETURNING uid, nombre`
        );
        if (result.rowCount > 0) {
            console.log(`>>> ✅ ${result.rowCount} usuarios reactivados automáticamente`);
            
            // Actualizar sanciones vencidas
            await pool.query(
                `UPDATE sanciones_usuarios 
                 SET activa = FALSE 
                 WHERE activa = TRUE 
                   AND fecha_fin IS NOT NULL 
                   AND fecha_fin < NOW()`
            );
        }
    } catch (error) {
        console.error('Error en cron de sanciones:', error);
    }
});
console.log('>>> ⏰ CRON de sanciones activado (cada hora)');

// ============================================================
// 🔥 RUTA DE PRUEBA
// ============================================================
app.get('/', (req, res) => {
    res.send('Backend del dashboard funcionando 🚀');
});

// ============================================================
// 🔥 RESUMEN GENERAL (KPIs)
// ============================================================
app.get('/api/admin/resumen', async (req, res) => {
    try {
        const usuarios = await pool.query('SELECT COUNT(*) FROM usuarios');
        const productos = await pool.query('SELECT COUNT(*) FROM productos_app');
        const productosActivos = await pool.query(
            "SELECT COUNT(*) FROM productos_app WHERE estado = 'activo' AND estado_moderacion = 'aprobado'"
        );
        const productosPendientes = await pool.query(
            "SELECT COUNT(*) FROM productos_app WHERE estado_moderacion = 'pendiente'"
        );
        const chats = await pool.query('SELECT COUNT(*) FROM conversaciones_app');
        const denuncias = await pool.query('SELECT COUNT(*) FROM denuncias');

        res.json({
            total_usuarios: parseInt(usuarios.rows[0].count),
            total_productos: parseInt(productos.rows[0].count),
            productos_activos: parseInt(productosActivos.rows[0].count),
            productos_pendientes: parseInt(productosPendientes.rows[0].count),
            total_chats: parseInt(chats.rows[0].count),
            total_denuncias: parseInt(denuncias.rows[0].count),
        });
    } catch (error) {
        console.error('Error en /api/admin/resumen:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 LISTA DE USUARIOS
// ============================================================
app.get('/api/admin/usuarios', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT uid, email, nombre, telefono, foto_perfil 
             FROM usuarios 
             ORDER BY nombre ASC 
             LIMIT 100`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error en /api/admin/usuarios:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 LISTA DE PRODUCTOS
// ============================================================
app.get('/api/admin/productos', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, nombre, precio, categoria, vendedor_nombre, 
                    imagen_url, estado, estado_moderacion, vistas, likes
             FROM productos_app 
             ORDER BY id DESC 
             LIMIT 100`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error en /api/admin/productos:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DENUNCIAS - CONTADOR (para el badge)
// ============================================================
app.get('/api/admin/denuncias/contador', async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT COUNT(*) FROM denuncias WHERE archivada = FALSE OR archivada IS NULL"
        );
        res.json({ nuevas: parseInt(result.rows[0].count) });
    } catch (error) {
        console.error('Error en contador denuncias:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DENUNCIAS - NUEVAS
// ============================================================
app.get('/api/admin/denuncias/nuevas', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT d.*, 
                    u1.nombre AS denunciante_nombre,
                    u2.nombre AS denunciado_nombre,
                    p.nombre AS producto_nombre,
                    p.imagen_url AS producto_imagen
             FROM denuncias d
             LEFT JOIN usuarios u1 ON d.denunciante_id = u1.uid
             LEFT JOIN usuarios u2 ON d.denunciado_id = u2.uid
             LEFT JOIN productos_app p ON d.producto_id = p.id
             WHERE d.archivada = FALSE OR d.archivada IS NULL
             ORDER BY d.fecha DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error en denuncias nuevas:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DENUNCIAS - ARCHIVADAS
// ============================================================
app.get('/api/admin/denuncias/archivadas', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT d.*, 
                    u1.nombre AS denunciante_nombre,
                    u2.nombre AS denunciado_nombre,
                    p.nombre AS producto_nombre,
                    p.imagen_url AS producto_imagen
             FROM denuncias d
             LEFT JOIN usuarios u1 ON d.denunciante_id = u1.uid
             LEFT JOIN usuarios u2 ON d.denunciado_id = u2.uid
             LEFT JOIN productos_app p ON d.producto_id = p.id
             WHERE d.archivada = TRUE
             ORDER BY d.fecha_archivado DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error en denuncias archivadas:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DENUNCIAS - ARCHIVAR
// ============================================================
app.put('/api/admin/denuncias/:id/archivar', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            `UPDATE denuncias 
             SET archivada = TRUE, fecha_archivado = NOW() 
             WHERE id = $1`,
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error al archivar:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DENUNCIAS - DESARCHIVAR
// ============================================================
app.put('/api/admin/denuncias/:id/desarchivar', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            `UPDATE denuncias 
             SET archivada = FALSE, fecha_archivado = NULL 
             WHERE id = $1`,
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error al desarchivar:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 INICIAR SERVIDOR
// ============================================================
// ============================================================
// 🔥 NOTIFICACIONES MASIVAS - ENVIAR
// ============================================================
app.post('/api/admin/notificaciones/enviar', async (req, res) => {
    try {
        const { titulo, mensaje, tipo } = req.body;

        if (!titulo || !mensaje) {
            return res.status(400).json({ error: 'Título y mensaje son obligatorios' });
        }

        const usuariosResult = await pool.query(
            `SELECT uid, fcm_token FROM usuarios 
             WHERE fcm_token IS NOT NULL AND fcm_token != ''`
        );

        const usuarios = usuariosResult.rows;
        console.log(`>>> 📢 Enviando notificación a ${usuarios.length} usuarios`);

        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             SELECT uid, NULL, $1, $2, NOW() FROM usuarios`,
            [`${titulo}\n${mensaje}`, tipo || 'info']
        );

        let enviadas = 0;
        let errores = 0;

        if (usuarios.length > 0) {
            const chunks = [];
            for (let i = 0; i < usuarios.length; i += 500) {
                chunks.push(usuarios.slice(i, i + 500));
            }

            for (const chunk of chunks) {
                const tokens = chunk.map(u => u.fcm_token);
                try {
                    const response = await admin.messaging().sendEachForMulticast({
                        tokens: tokens,
                        notification: {
                            title: titulo,
                            body: mensaje
                        },
                        data: {
                            tipo: tipo || 'info',
                            tipoNotif: 'masiva'
                        }
                    });
                    enviadas += response.successCount;
                    errores += response.failureCount;
                } catch (err) {
                    console.error('Error en chunk:', err.message);
                    errores += chunk.length;
                }
            }
        }

        const result = await pool.query(
            `INSERT INTO notificaciones_masivas 
             (titulo, mensaje, tipo, destinatarios, total_enviadas, fecha)
             VALUES ($1, $2, $3, $4, $5, NOW())
             RETURNING *`,
            [titulo, mensaje, tipo || 'info', 'todos', enviadas]
        );

        console.log(`>>> ✅ Push: ${enviadas} enviadas, ${errores} fallidas`);

        res.json({
            success: true,
            total_usuarios: usuarios.length,
            enviadas: enviadas,
            errores: errores,
            notificacion: result.rows[0]
        });
    } catch (error) {
        console.error('Error al enviar notificación:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 NOTIFICACIONES MASIVAS - HISTORIAL
// ============================================================
app.get('/api/admin/notificaciones/historial', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM notificaciones_masivas 
             ORDER BY fecha DESC 
             LIMIT 50`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener historial:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 BUSCAR USUARIO POR NOMBRE/EMAIL
// ============================================================
app.get('/api/admin/usuarios/buscar', async (req, res) => {
    try {
        const { q } = req.query;
        if (!q || q.length < 2) {
            return res.json([]);
        }
        const result = await pool.query(
            `SELECT uid, email, nombre, foto_perfil 
             FROM usuarios 
             WHERE nombre ILIKE $1 OR email ILIKE $1
             LIMIT 20`,
            [`%${q}%`]
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error al buscar usuarios:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 DETALLE DE USUARIO (con estadísticas y sanciones)
// ============================================================
app.get('/api/admin/usuarios/:uid/detalle', async (req, res) => {
    try {
        const { uid } = req.params;

        // 1. Info del usuario
        const userResult = await pool.query(
            `SELECT uid, email, nombre, telefono, foto_perfil, 
                    estado_cuenta, motivo_sancion, fecha_fin_sancion
             FROM usuarios WHERE uid = $1`,
            [uid]
        );
        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        // 2. Contar productos
        const productosResult = await pool.query(
            `SELECT COUNT(*) FROM productos_app WHERE vendedor_id = $1`,
            [uid]
        );

        // 3. Contar denuncias en su contra
        const denunciasResult = await pool.query(
            `SELECT COUNT(*) FROM denuncias WHERE denunciado_id = $1`,
            [uid]
        );

        // 4. Historial de sanciones
        const sancionesResult = await pool.query(
            `SELECT * FROM sanciones_usuarios 
             WHERE usuario_id = $1 
             ORDER BY fecha_inicio DESC 
             LIMIT 20`,
            [uid]
        );

        res.json({
            usuario: userResult.rows[0],
            total_productos: parseInt(productosResult.rows[0].count),
            total_denuncias: parseInt(denunciasResult.rows[0].count),
            sanciones: sancionesResult.rows,
        });
    } catch (error) {
        console.error('Error en detalle usuario:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 ENVIAR MENSAJE DIRECTO AL USUARIO
// ============================================================
app.post('/api/admin/usuarios/:uid/mensaje', async (req, res) => {
    try {
        const { uid } = req.params;
        const { titulo, mensaje } = req.body;

        if (!titulo || !mensaje) {
            return res.status(400).json({ error: 'Título y mensaje obligatorios' });
        }

        // Insertar alerta
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'mensaje_admin', NOW())`,
            [uid, `${titulo}\n${mensaje}`]
        );

        // Enviar push si tiene token
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`,
            [uid]
        );
        const token = userResult.rows[0]?.fcm_token;

        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: { title: titulo, body: mensaje },
                    data: { tipo: 'mensaje_admin' }
                });
            } catch (pushError) {
                console.error('Error push mensaje:', pushError.message);
            }
        }

        res.json({ success: true, mensaje: 'Mensaje enviado' });
    } catch (error) {
        console.error('Error al enviar mensaje:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 ADVERTIR USUARIO
// ============================================================
app.post('/api/admin/usuarios/:uid/advertir', async (req, res) => {
    try {
        const { uid } = req.params;
        const { motivo } = req.body;

        if (!motivo) {
            return res.status(400).json({ error: 'Motivo obligatorio' });
        }

        // Actualizar estado
        await pool.query(
            `UPDATE usuarios 
             SET estado_cuenta = 'advertido', motivo_sancion = $1 
             WHERE uid = $2`,
            [motivo, uid]
        );

        // Registrar sanción
        await pool.query(
            `INSERT INTO sanciones_usuarios 
             (usuario_id, tipo, motivo, fecha_inicio, fecha_fin, activa)
             VALUES ($1, 'advertencia', $2, NOW(), NULL, TRUE)`,
            [uid, motivo]
        );

        // Alerta al usuario
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'advertencia', NOW())`,
            [uid, `⚠️ Has recibido una advertencia:\n\n${motivo}`]
        );

        // Push
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`, [uid]
        );
        const token = userResult.rows[0]?.fcm_token;
        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '⚠️ Advertencia',
                        body: motivo.length > 100 ? motivo.substring(0, 100) + '...' : motivo
                    },
                    data: { tipo: 'advertencia' }
                });
            } catch (e) { console.error('Push advertir:', e.message); }
        }

        res.json({ success: true, mensaje: 'Usuario advertido' });
    } catch (error) {
        console.error('Error al advertir:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SUSPENDER USUARIO
// ============================================================
app.post('/api/admin/usuarios/:uid/suspender', async (req, res) => {
    try {
        const { uid } = req.params;
        const { motivo, dias } = req.body;

        if (!motivo || !dias) {
            return res.status(400).json({ error: 'Motivo y días obligatorios' });
        }

        const diasInt = parseInt(dias);
        if (isNaN(diasInt) || diasInt < 1) {
            return res.status(400).json({ error: 'Días inválidos' });
        }

        // Actualizar usuario
        await pool.query(
            `UPDATE usuarios 
             SET estado_cuenta = 'suspendido', 
                 motivo_sancion = $1,
                 fecha_fin_sancion = NOW() + INTERVAL '${diasInt} days'
             WHERE uid = $2`,
            [motivo, uid]
        );

        // Registrar sanción
        await pool.query(
            `INSERT INTO sanciones_usuarios 
             (usuario_id, tipo, motivo, fecha_inicio, fecha_fin, activa)
             VALUES ($1, 'suspension', $2, NOW(), NOW() + INTERVAL '${diasInt} days', TRUE)`,
            [uid, motivo]
        );

        // Alerta
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'suspension', NOW())`,
            [uid, `🚫 Tu cuenta ha sido suspendida por ${diasInt} días:\n\n${motivo}`]
        );

        // Push
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`, [uid]
        );
        const token = userResult.rows[0]?.fcm_token;
        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '🚫 Cuenta suspendida',
                        body: `Has sido suspendido por ${diasInt} días. Motivo: ${motivo}`
                    },
                    data: { tipo: 'suspension' }
                });
            } catch (e) { console.error('Push suspender:', e.message); }
        }

        res.json({ success: true, mensaje: `Usuario suspendido por ${diasInt} días` });
    } catch (error) {
        console.error('Error al suspender:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 BANEAR USUARIO
// ============================================================
app.post('/api/admin/usuarios/:uid/banear', async (req, res) => {
    try {
        const { uid } = req.params;
        const { motivo } = req.body;

        if (!motivo) {
            return res.status(400).json({ error: 'Motivo obligatorio' });
        }

        // Actualizar usuario
        await pool.query(
            `UPDATE usuarios 
             SET estado_cuenta = 'baneado', 
                 motivo_sancion = $1,
                 fecha_fin_sancion = NULL
             WHERE uid = $2`,
            [motivo, uid]
        );

        // Registrar sanción
        await pool.query(
            `INSERT INTO sanciones_usuarios 
             (usuario_id, tipo, motivo, fecha_inicio, fecha_fin, activa)
             VALUES ($1, 'baneo', $2, NOW(), NULL, TRUE)`,
            [uid, motivo]
        );

        // Alerta
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'baneo', NOW())`,
            [uid, `⛔ Tu cuenta ha sido bloqueada permanentemente:\n\n${motivo}`]
        );

        // Push
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`, [uid]
        );
        const token = userResult.rows[0]?.fcm_token;
        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '⛔ Cuenta bloqueada',
                        body: `Tu cuenta ha sido bloqueada permanentemente. Motivo: ${motivo}`
                    },
                    data: { tipo: 'baneo' }
                });
            } catch (e) { console.error('Push banear:', e.message); }
        }

        res.json({ success: true, mensaje: 'Usuario baneado' });
    } catch (error) {
        console.error('Error al banear:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 REACTIVAR USUARIO
// ============================================================
app.post('/api/admin/usuarios/:uid/reactivar', async (req, res) => {
    try {
        const { uid } = req.params;

        // Actualizar usuario
        await pool.query(
            `UPDATE usuarios 
             SET estado_cuenta = 'activo', 
                 motivo_sancion = NULL,
                 fecha_fin_sancion = NULL
             WHERE uid = $1`,
            [uid]
        );

        // Desactivar sanciones activas
        await pool.query(
            `UPDATE sanciones_usuarios 
             SET activa = FALSE 
             WHERE usuario_id = $1 AND activa = TRUE`,
            [uid]
        );

        // Alerta
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'exito', NOW())`,
            [uid, `✅ Tu cuenta ha sido reactivada. Ya puedes usar la app normalmente.`]
        );

        // Push
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`, [uid]
        );
        const token = userResult.rows[0]?.fcm_token;
        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '✅ Cuenta reactivada',
                        body: 'Tu cuenta ha sido reactivada'
                    },
                    data: { tipo: 'reactivacion' }
                });
            } catch (e) { console.error('Push reactivar:', e.message); }
        }

        res.json({ success: true, mensaje: 'Usuario reactivado' });
    } catch (error) {
        console.error('Error al reactivar:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 INICIAR SERVIDOR
// ============================================================
// ============================================================
// 🔥 ELIMINAR PRODUCTO (marcar como eliminado)
// ============================================================
app.put('/api/admin/productos/:id/eliminar', async (req, res) => {
    try {
        const { id } = req.params;

        // 1. Obtener datos del producto y vendedor
        const productoResult = await pool.query(
            `SELECT id, nombre, vendedor_id FROM productos_app WHERE id = $1`,
            [id]
        );

        if (productoResult.rows.length === 0) {
            return res.status(404).json({ error: 'Producto no encontrado' });
        }

        const producto = productoResult.rows[0];
        const motivo = 'Violó las normas de la comunidad';

        // 2. Marcar como eliminado
        await pool.query(
            `UPDATE productos_app 
             SET estado_moderacion = 'eliminado_admin',
                 motivo_rechazo = $1
             WHERE id = $2`,
            [motivo, id]
        );

        // 3. Notificar al vendedor (alerta en la BD)
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, $2, $3, 'error', NOW())`,
            [
                producto.vendedor_id,
                id,
                `❌ Tu producto "${producto.nombre}" fue eliminado por un administrador.\n\nMotivo: ${motivo}`
            ]
        );

        // 4. Enviar push si el vendedor tiene token
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`,
            [producto.vendedor_id]
        );
        const token = userResult.rows[0]?.fcm_token;

        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '❌ Producto eliminado',
                        body: `Tu producto "${producto.nombre}" fue eliminado. Motivo: ${motivo}`
                    },
                    data: {
                        tipo: 'producto_eliminado',
                        productoId: id.toString()
                    }
                });
            } catch (pushError) {
                console.error('Error push producto eliminado:', pushError.message);
            }
        }

        console.log(`>>> 🗑️ Producto ${id} eliminado por admin`);

        res.json({
            success: true,
            mensaje: 'Producto eliminado',
            producto_id: id
        });
    } catch (error) {
        console.error('Error al eliminar producto:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 RESTAURAR PRODUCTO ELIMINADO
// ============================================================
app.put('/api/admin/productos/:id/restaurar', async (req, res) => {
    try {
        const { id } = req.params;

        const productoResult = await pool.query(
            `SELECT id, nombre, vendedor_id FROM productos_app WHERE id = $1`,
            [id]
        );

        if (productoResult.rows.length === 0) {
            return res.status(404).json({ error: 'Producto no encontrado' });
        }

        const producto = productoResult.rows[0];

        // Restaurar: vuelve a estado aprobado
        await pool.query(
            `UPDATE productos_app 
             SET estado_moderacion = 'aprobado',
                 motivo_rechazo = NULL
             WHERE id = $1`,
            [id]
        );

        // Notificar al vendedor
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, $2, $3, 'exito', NOW())`,
            [
                producto.vendedor_id,
                id,
                `✅ Tu producto "${producto.nombre}" ha sido restaurado por un administrador y ya está visible.`
            ]
        );

        // Push
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`,
            [producto.vendedor_id]
        );
        const token = userResult.rows[0]?.fcm_token;

        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '✅ Producto restaurado',
                        body: `Tu producto "${producto.nombre}" ya está visible nuevamente.`
                    },
                    data: {
                        tipo: 'producto_restaurado',
                        productoId: id.toString()
                    }
                });
            } catch (pushError) {
                console.error('Error push restaurar:', pushError.message);
            }
        }

        console.log(`>>> ✅ Producto ${id} restaurado por admin`);

        res.json({
            success: true,
            mensaje: 'Producto restaurado',
            producto_id: id
        });
    } catch (error) {
        console.error('Error al restaurar producto:', error);
        res.status(500).json({ error: error.message });
    }
});
// ============================================================
// 🔥 SOPORTE - CONTADOR (para el badge)
// ============================================================
app.get('/api/admin/soporte/contador', async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT COUNT(*) FROM mensajes_soporte WHERE estado = 'nuevo'"
        );
        res.json({ nuevos: parseInt(result.rows[0].count) });
    } catch (error) {
        console.error('Error contador soporte:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SOPORTE - LISTA NUEVOS
// ============================================================
app.get('/api/admin/soporte/nuevos', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM mensajes_soporte 
             WHERE estado = 'nuevo' OR estado = 'leido'
             ORDER BY fecha DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error soporte nuevos:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SOPORTE - LISTA RESPONDIDOS
// ============================================================
app.get('/api/admin/soporte/respondidos', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM mensajes_soporte 
             WHERE estado = 'respondido' OR estado = 'cerrado'
             ORDER BY fecha_respuesta DESC`
        );
        res.json(result.rows);
    } catch (error) {
        console.error('Error soporte respondidos:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SOPORTE - RESPONDER
// ============================================================
app.post('/api/admin/soporte/:id/responder', async (req, res) => {
    try {
        const { id } = req.params;
        const { respuesta } = req.body;

        if (!respuesta || respuesta.trim().isEmpty) {
            return res.status(400).json({ error: 'La respuesta no puede estar vacía' });
        }

        // 1. Verificar que existe
        const msgResult = await pool.query(
            `SELECT id, usuario_id, asunto FROM mensajes_soporte WHERE id = $1`,
            [id]
        );

        if (msgResult.rows.length === 0) {
            return res.status(404).json({ error: 'Mensaje no encontrado' });
        }

        const msg = msgResult.rows[0];

        // 2. Actualizar con la respuesta
        await pool.query(
            `UPDATE mensajes_soporte 
             SET respuesta = $1, 
                 estado = 'respondido',
                 fecha_respuesta = NOW()
             WHERE id = $2`,
            [respuesta, id]
        );

        // 3. Insertar alerta para el usuario
        await pool.query(
            `INSERT INTO alertas (usuario_id, producto_id, mensaje, tipo, fecha)
             VALUES ($1, NULL, $2, 'exito', NOW())`,
            [
                msg.usuario_id,
                `📬 Respuesta de Soporte:\n\n${respuesta}`
            ]
        );

        // 4. Enviar push si el usuario tiene token
        const userResult = await pool.query(
            `SELECT fcm_token FROM usuarios WHERE uid = $1`,
            [msg.usuario_id]
        );
        const token = userResult.rows[0]?.fcm_token;

        if (token) {
            try {
                await admin.messaging().send({
                    token: token,
                    notification: {
                        title: '📬 Soporte te respondió',
                        body: respuesta.length > 100 
                            ? respuesta.substring(0, 100) + '...' 
                            : respuesta
                    },
                    data: {
                        tipo: 'soporte_respuesta',
                        mensajeId: id.toString()
                    }
                });
            } catch (pushError) {
                console.error('Error push soporte:', pushError.message);
            }
        }

        console.log(`>>> 📬 Soporte ${id} respondido`);

        res.json({ success: true, mensaje: 'Respuesta enviada' });
    } catch (error) {
        console.error('Error al responder soporte:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SOPORTE - MARCAR COMO LEÍDO
// ============================================================
app.put('/api/admin/soporte/:id/leido', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            `UPDATE mensajes_soporte 
             SET estado = 'leido' 
             WHERE id = $1 AND estado = 'nuevo'`,
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error marcar leído:', error);
        res.status(500).json({ error: error.message });
    }
});

// ============================================================
// 🔥 SOPORTE - CERRAR
// ============================================================
app.put('/api/admin/soporte/:id/cerrar', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            `UPDATE mensajes_soporte 
             SET estado = 'cerrado' 
             WHERE id = $1`,
            [id]
        );
        res.json({ success: true });
    } catch (error) {
        console.error('Error cerrar soporte:', error);
        res.status(500).json({ error: error.message });
    }
});
app.listen(port, '0.0.0.0', () => {
    console.log(`>>> 🚀 Backend dashboard corriendo en http://0.0.0.0:${port}`);
});