import { Component } from 'preact';
import { pb } from './app'
import './index.css'

interface GameState {
  created: string,
  finished: boolean,
  rockets_launched: number,
  time_played: number
}

interface HomeProps { }
interface HomeState {
  current_games: GameState[],
  games: GameState[]
}

export default class Home extends Component<HomeProps, HomeState> {
  constructor() {
    super()
    this.setState({
      current_games: [],
      games: []
    })
  }
  async componentDidMount() {
    const records = await pb.collection("games").getFullList({}) as GameState[]
    this.setState({
      games: records,
    })
  }

  render() {
    console.log(this.state.games);
    return (
      <>
        <h3> Game Status: <span>{this.state.current_games.length !== 0 ? "In Game" : "In Lobby"}</span></h3>
        <table>
          <thead>
            <th>Started At</th>
            <th>Game Length</th>
            <th>Rockets Launched</th>
            <th>Status</th>
          </thead>
          <tbody>
            {this.state.games.map(v => {
              return (<tr>
                <td>{v.created}</td>
                <td>{v.time_played}</td>
                <td>{v.rockets_launched}</td>
                <td>{v.finished ? "Completed" : "On-Going"}</td>
              </tr>)
            })}
          </tbody>
        </table>
      </>
    )
  }
}
