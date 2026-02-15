import express from "express";
import http from "http";
import app from "./route.js";


app.use('/uploads', express.static('uploads'));

const server = http.createServer(app);
const PORT = process.env.PORT || 55000;
server.listen(PORT,()=>{
    console.log("Server is listening on " , PORT);
});