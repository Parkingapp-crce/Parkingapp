import 'dotenv/config'
import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});

const prisma = new PrismaClient({
  adapter,
});

const app = express();

app.use(cors());
app.use(bodyParser.json());

/// 🔐 SINGLE SECRET
const SECRET = process.env.JWT_SECRET;


/// TEST ROUTE
app.get("/", (req, res) => {
  res.send("Backend running successfully");
});

/// 🔐 REGISTER
app.post("/register", async (req, res) => {
  const { name, email, password } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
      },
    });

    res.json({ message: "User registered successfully" });

  } catch (error) {
    res.json({ message: "User already exists" });
  }
});

/// 🔐 LOGIN
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    return res.json({ message: "Invalid credentials" });
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.json({ message: "Invalid credentials" });
  }

  const token = jwt.sign(
    { userId: user.id, email: user.email },
    SECRET,
    { expiresIn: "1d" }
  );

  res.json({
    message: "Login successful",
    token: token,
  });
});

/// 🔒 AUTH MIDDLEWARE
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];

  if (!authHeader) {
    return res.status(401).json({ message: "No token" });
  }

  const token = authHeader.split(" ")[1];

  jwt.verify(token, SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: "Invalid token" });
    }

    req.user = user;
    next();
  });
}

/// 🔐 PROTECTED ROUTE
app.get("/profile", authenticateToken, async (req, res) => {

  const user = await prisma.user.findUnique({
    where: { id: req.user.userId },
  });

  res.json({
    user: {
      email: user.email,
      name: user.name,
    },
  });
});

/// 🚀 START SERVER
app.listen(3000, () => {
  console.log("Server running on port 3000");
});