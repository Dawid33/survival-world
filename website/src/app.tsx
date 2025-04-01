import { Component, createContext } from 'preact'
import { Router, Route } from 'preact-router';
import PocketBase from 'pocketbase';
import Home from './home';
import Login from './login';
import styles from "./app.module.css"
import generic from "./generic.module.css"
import './index.css'

export const pb = new PocketBase('https://factoriosurvivalworld.com/db');

export function Header() {
  return (
    <>
      <header class={`${styles.header}`}>
        <h2>Survival World</h2>
      </header>
    </>
  )
}

function SideBar({ children }) {
  return <nav class={`${styles.nav} ${generic.frame}`}>{this.props.children}</nav>
}

function SideBarElement({ text, path }) {
  return <a class={`${styles.navLink} ${generic.frame_list_item}`} href={this.props.path}>{this.props.text}</a>
}

export function ContentWrapper({ children }) {
  return <section class={`${styles.content} ${generic.frame}`}>{children}</section>
}


export function App() {
  console.log("running app")
  return (
    <>
      <main class={`${styles.main} ${generic.panel}`}>
        <Header />
        <SideBar>
          <SideBarElement text="Home" path="/" />
          <SideBarElement text="Login" path="/login" />
        </SideBar>
        <ContentWrapper>
          <Router>
            <Route path="/" component={Home} />
            <Route path="/login" component={Login} />
          </Router>
        </ContentWrapper>
      </main>
    </>
  )
}
