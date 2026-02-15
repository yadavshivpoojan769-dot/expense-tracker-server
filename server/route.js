
// const cors = require('cors');
// const express=require("express");
// const app=express();
// const bodyparser = require('body-parser');

import bodyParser from 'body-parser';
import cors from 'cors';
import express from 'express';
const app=express();
// import app from express();

app.use(cors());
app.use(express.json());
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({
    extended: true
}));

// const signup=require("./api/signup.js");
// const login=require("./api/login.js");
// const showdata=require("./api/showdata.js");

import login from './api/login.js';
import showdata from './api/showdata.js';
import signup from "./api/signup.js";
import userdetails from "./api/userdetails.js";
//routes
app.use("/signup",signup);
app.use("/login",login);
app.use("/showdata",showdata);
app.use("/userdetails",userdetails);

export default app;



